require "spec_helper"
require "chef/mixin/shell_out"
require "benchmark" unless defined?(Benchmark)

describe "ohai" do
  include Chef::Mixin::ShellOut

  let(:ohai) { "bundle exec ohai" }

  describe "testing ohai performance" do
    # The purpose of this test is to generally find misconfigured DNS on
    # CI testers.  If this fails, it is probably because the forward+reverse
    # DNS lookup that node[:hostname] needs is timing out and failing.
    #
    # If it is failing spuriously, it may mean DNS is failing spuriously, the
    # best solution will be to make sure that `hostname -f`-like behavior hits
    # /etc/hosts and not DNS.
    #
    # If it still fails supriously, it is possible that the server has high
    # CPU load (e.g. due to background processes) which are contending with the
    # running tests (disable the screensaver on servers, stop playing Fortnite
    # while you're running tests, etc).
    #
    # If this just fails due to I/O being very slow and ruby being very slow to
    # startup then that still indicates that the tester configuration needs
    # fixing.  The fact that this will fail on a windows box on a virt that doesn't
    # use an SSD is because we have a higher bar for the tests to run successfully
    # and that configuration is broken, so this test is red for a reason.
    #
    # This will probably fail on raspberry pi's or something like that as well.  That
    # is not a bug.  We will never accept a raspberry pi as a CI tester for our
    # software.  Feel free to manually delete and thereby skip this file in your
    # own testing harness, but that is not our concern, we are testing behavior
    # that is critical to our infrastructure and must run in our tests.
    #
    # XXX: unfortunately this is so slow on our windows testers (~9 seconds on one
    # tester) that we can't enable it for windows unless we get some better perf there.
    #
    it "the hostname plugin must return in under 4 seconds (see comments in code)" do
      # unfortunately this doesn't look stable enough to enable
      skip "we need to do more performance work on windows and s390x testers before this can be enabled"
      delta = Benchmark.realtime do
        shell_out!("#{ohai} hostname")
      end
      expect(delta).to be < 4
    end

    # The purpose of this is to give some indication of if shell_out is slow or
    # if the hostname plugin itself is slow.  If this test is also failing that we
    # almost certainly have some kind of issue with DNS timeouts, etc.  If this
    # test succeeds and the other one fails, then it can be some kind of shelling-out
    # issue or poor performance due to I/O on starting up ruby to run ohai, etc.
    #
    # @todo: This is disbled 4.26.2021 so we can ship 17.0
    # it "the hostname plugin must return in under 2 seconds when called from pure ruby" do
    #   delta = Benchmark.realtime do
    #     Ohai::System.new.all_plugins(["hostname"])
    #   end
    #   expect(delta).to be < 2
    # end
  end
end
