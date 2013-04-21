require "shellex/version"
require 'popen4'

class ShellExecutionError < StandardError; end
class ShellExecutionFailed < ShellExecutionError
  attr_accessor :output_without_command
end
class ShellExecutionTimeout < ShellExecutionError; end
class ShellArgumentMissing < ShellExecutionError; end

module Kernel
  SHELLEX_IO_BUFFER = 32*1024
  DEFAULT_TIMEOUT = 5*60

  def _shellex_retvalue(ret)
    def ret.stdout; self[0] end
    def ret.stderr; self[1] end
    def ret.to_s; stdout end
    def ret.to_str; stdout end
    ret.freeze
  end

  def _shellex_extend_status(status)
    def status.command=(cmd)
      @command = cmd
    end
    def status.command
      @command
    end
  end

  def shellex(cmd, *args)
    stdout, stderr, status = silent_shellex(cmd, *args)
    if status.success?
      ret = [stdout, stderr]
      return _shellex_retvalue(ret)
    else
      exc = ShellExecutionFailed.new("#{status.command} (exit code: #{status.exitstatus})\nOutput: #{stderr}")
      exc.output_without_command = stderr
      raise exc
    end
  end

  def silent_shellex(cmd, *args)
    opts = {:timeout => DEFAULT_TIMEOUT, :close_stdin => true}
    if args.last.is_a?(Hash)
      opts = opts.merge(args.pop)
    end

    cmd = cmd.with_args(*args)
    out, err, pid, status = '', '', nil, nil

    begin
      Timeout.timeout(opts[:timeout].to_i) do
        status = Open4.open4(cmd) do |pid, stdin, stdout, stderr|
          stdin.write(opts[:input]) if opts[:input]
          stdin.close if opts[:close_stdin]

          while tmp = stdout.read(SHELLEX_IO_BUFFER)
            out << tmp
          end

          while tmp = stderr.read(SHELLEX_IO_BUFFER)
            err << tmp
          end
        end
      end
    rescue Exception => e
      if pid
        Process.kill 9, pid
        Process.wait pid
      end

      # Exceptions coming from popen4 are deserialized from forked process, so they are not caught by listing
      # class name in rescue clause
      case e.class.to_s
        when /Timeout::Error/
          raise ShellExecutionTimeout, "Timeout after #{opts[:timeout]} secs while running '#{cmd}'"
        else
          raise ShellExecutionError, e.message
      end
    end

    _shellex_debug(cmd, err, opts, out)

    _shellex_extend_status(status)
    status.command = cmd

    return out, err, status
  end

  def _shellex_debug(cmd, err, opts, out)
    if defined?(Rails) and Rails.env.development?
      Rails.logger.info { "Executed: #{cmd}\n STDIN: #{opts[:input].inspect} STDOUT: #{out.inspect}\nSTDERR: #{err.inspect}" }
    end
  end
end

class String
  def with_args(*args)
    escape = proc do |val|
      val = val.to_s
      if val.empty? or val.strip == ""
        return "''"
      end
      val.split(/'/, -1).map{|e| "'#{e}'"}.join("\\'")
    end
    ignore_nil = proc { |val| escape.call(val) unless val.nil? }

    gsub(/(\?\&|\?\?|\?\!|\?~|\?)/) do |match|
      val = args.shift

      case match
        when "?~" # Escape question mark
          "?"
        when "?!" # Argument can't be nil
          if val.nil?
            raise ShellArgumentMissing, "Argument marked as required with ?! is nil"
          else
            escape.call(val)
          end
        when "??" # Argument will be omitted if nil
          ignore_nil.call(val)
        when "?" # Argument will be escaped even if nil
          escape.call(val)
        when "?&" # Argument has to be array and each element will be escaped or ommitted if nil
          if val.is_a?(Array)
            val.map(&ignore_nil).compact.join(" ")
          else
            raise ShellArgumentMissing, "If ?& is present in this position, #{val.inspect} should be an Array"
          end
      end
    end.strip
  end
end
