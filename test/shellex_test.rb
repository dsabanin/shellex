require 'shellex'
require 'test/unit'
require 'shoulda/context'

class ShellexTest < Test::Unit::TestCase

  context "ShellEx" do

    context "capturing" do
      should "stdout capturing" do
        stdout, stderr = shellex("echo stdout")
        assert_equal "stdout\n", stdout
        assert_equal "", stderr
      end

      should "stderr capturing" do
        stdout, stderr = shellex("echo stderr 1>&2")
        assert_equal "", stdout
        assert_equal "stderr\n", stderr
      end

      should "stdout and stderr capturing" do
        stdout, stderr = shellex("echo stdout; echo stderr 1>&2")
        assert_equal "stdout\n", stdout
        assert_equal "stderr\n", stderr
      end
    end

    should "eat stdin input" do
      stdout, stderr = shellex("cat -", :input => "hello")
      assert_equal "hello", stdout
    end

    should "timeout" do
      assert_raises(ShellExecutionTimeout) do
        shellex("sleep 10", :timeout => 1)
      end
    end

    should "timeout on blocking io" do
      assert_raises(ShellExecutionTimeout) do
        shellex("cat /dev/stdin", :timeout => 1, :close_stdin => false)
      end
    end

    context "interpolation" do
      should "interpolate and escape the args" do
        real = "echo ? ? ?".with_args(1, "blah", :symbol)
        assert_equal "echo '1' 'blah' 'symbol'", real
      end

      should "interpolate ?& as series of args" do
        real = "? ?&".with_args("echo", [1,2,3,4])
        assert_equal "'echo' '1' '2' '3' '4'", real
      end

      should "interpolate ?& as series of args in the middle" do
        real = "? ?& ?".with_args("echo", [1,2,3,4], "abc")
        assert_equal "'echo' '1' '2' '3' '4' 'abc'", real
      end

      should "raise error if array for ?& is not given" do
        assert_raises(ShellArgumentMissing) do
          "? ?& ?".with_args("echo", 1)
        end
      end

      should "interpolate empty array to empty space" do
        real = "? ?& ?".with_args("echo", [], "abc")
        assert_equal "'echo'  'abc'", real
      end

      should "interpolate nil in array to empty space" do
        real = "? ?& ?".with_args("echo", [1, nil, 3], "abc")
        assert_equal "'echo' '1' '3' 'abc'", real
      end

      should "interpolate on shellex call" do
        stdout, stderr = shellex("? ?", "echo", "stdout")
        assert_equal "stdout\n", stdout
      end

      should "interpolate nil value as empty string with ?" do
        real = "? ?".with_args("echo", nil)
        assert_equal "'echo' ''", real

        real = "? ?".with_args("echo", "blah")
        assert_equal "'echo' 'blah'", real
      end

      should "ignore nil values with ??" do
        real = "? ??".with_args("echo", nil)
        assert_equal "'echo'", real

        real = "? ??".with_args("echo", "blah")
        assert_equal "'echo' 'blah'", real
      end

      should "raise on required arguments" do
        assert_raises(ShellArgumentMissing) do
          real = "? ?!".with_args("echo", nil)
        end

        real = "? ??".with_args("echo", "blah")
        assert_equal "'echo' 'blah'", real
      end

      should "be able to escape the question mark" do
        real = "? ?~".with_args("echo", "ello")
        assert_equal "'echo' ?", real
      end
    end

    context "error handling" do
      should "raise error if exit value is not zero" do
        assert_raises(ShellExecutionFailed) do
          shellex("test a = b")
        end
      end

      should "have silent version that eats errors" do
        cmd = "echo ? 1>&2; test a = ?"
        stdout, stderr, status = silent_shellex(cmd, "stderr", "b")
        assert_equal "", stdout
        assert stderr.include?("stderr"), "Got: #{stderr}"
        assert_equal false, status.success?
        assert_equal "echo 'stderr' 1>&2; test a = 'b'", status.command
      end
    end

    context "should have singleton-array api" do
      should "provide stdout/stderr methods" do
        api = shellex("echo test")
        assert_equal "test\n", api.stdout
        assert_equal "test\n", api.to_s
        assert_equal "test\n", api.to_str
        assert_equal "", api.stderr
        assert api.frozen?
      end
    end
  end
end
