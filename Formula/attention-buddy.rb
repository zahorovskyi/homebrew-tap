# Homebrew formula for Attention Buddy: https://github.com/zahorovskyi/attention-buddy
class AttentionBuddy < Formula
  desc "Floating macOS icon that waves when a Claude Code session needs you"
  homepage "https://github.com/zahorovskyi/attention-buddy"
  url "https://github.com/zahorovskyi/attention-buddy/archive/refs/tags/v0.1.0.tar.gz"
  sha256 "5df6c15ae804be5efb84defe0fdbfb4f62a4e2638841ece1202935395d21f3eb"
  license "MIT"
  head "https://github.com/zahorovskyi/attention-buddy.git", branch: "main"

  depends_on "jq"
  depends_on macos: :ventura

  def install
    system "./scripts/build.sh", "--output", buildpath/"attention-buddy"
    bin.install "attention-buddy"
    pkgshare.install "hooks/attention-buddy-hook.sh", "install.sh"
  end

  def caveats
    <<~EOS
      Connect it to Claude Code (adds hooks to ~/.claude/settings.json, with a backup):
        attention-buddy setup

      Start the icon now and at every login:
        brew services start attention-buddy

      Check the setup any time:
        attention-buddy doctor
    EOS
  end

  service do
    run [opt_bin/"attention-buddy"]
    keep_alive successful_exit: false
    process_type :interactive
    log_path var/"log/attention-buddy.log"
    error_log_path var/"log/attention-buddy.log"
  end

  test do
    ENV["ATTENTION_BUDDY_DIR"] = testpath/"state"
    hook = pkgshare/"attention-buddy-hook.sh"
    event = '{"hook_event_name":"PermissionRequest","session_id":"test-1",' \
            '"tool_name":"Bash","tool_input":{"command":"ls"}}'
    pipe_output(hook, event)
    state = JSON.parse((testpath/"state/test-1.json").read)
    assert_equal "needs", state["status"]
    assert_equal "Bash", state["tool"]
    assert_match version.to_s, shell_output("#{bin}/attention-buddy --version")
  end
end
