# =============================================================================
# Hermes Agent — Homebrew Tap Formula
# https://github.com/NousResearch/hermes-agent
# Version: v2026.4.16  (v0.10.0)
# License: MIT
# =============================================================================
#
# Installation (replace <your-username> with your GitHub username):
#
#   brew tap <your-username>/hermes https://github.com/<your-username>/homebrew-hermes
#   brew install hermes-agent
#
# After install:
#   source ~/.zshrc
#   hermes setup
#
# Upgrade / uninstall:
#   brew upgrade hermes-agent
#   brew uninstall hermes-agent
# =============================================================================

class HermesAgent < Formula
  desc "Self-improving AI agent by Nous Research"
  homepage "https://github.com/NousResearch/hermes-agent"

  # Using the official install.sh as the source
  # SHA256 will be verified on first install (auto-prompted by Homebrew)
  url "https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh"
  version "v2026.4.16"
  license "MIT"

  # NOTE: The install.sh script handles all runtime dependencies:
  #   - uv (Python package manager) — auto-installed by script if missing
  #   - Python 3.11 — auto-installed by uv if missing
  #   - Git — required (system git on macOS)
  #   - Node.js 22 — auto-installed by script if missing
  #   - ripgrep, ffmpeg — auto-installed via brew if available

  # We only declare hard runtime deps that the script definitely needs
  depends_on "git"

  def install
    # Homebrew already downloaded install.sh into buildpath (via the `url` directive)
    # The downloaded file retains the original name from the URL
    install_sh = buildpath/"install.sh"
    chmod "+x", install_sh

    # The install script puts code at: ~/.hermes/hermes-agent
    # and symlinks hermes → ~/.local/bin/hermes
    #
    # For Homebrew, we want everything under HOMEBREW_PREFIX/hermes-agent.
    hermes_home = etc/"hermes"
    install_dir = prefix/"hermes-agent"

    # Ensure ~/.local/bin exists (install.sh needs it)
    (Pathname.new(ENV["HOME"])/".local/bin").mkpath

    # Run the official installer non-interactively
    system "/bin/bash", install_sh.to_s,
           "--hermes-home", hermes_home.to_s,
           "--dir", install_dir.to_s,
           "--skip-setup"

    # After install, the script symlinks hermes → ~/.local/bin/hermes
    # Also create a bin/hermes stub so `which hermes` works inside Homebrew env
    venv_hermes = install_dir/"venv/bin/hermes"
    if venv_hermes.exist?
      bin.install_symlink venv_hermes
    end
  end

  def post_install
    # Add ~/.local/bin to shell PATH configs (same logic as install.sh)
    shell_configs.each do |rc|
      next unless rc.exist?
      next if rc.read.include?("/.local/bin")
      append_to_file(rc, "\n# Hermes Agent (Homebrew)\nexport PATH=\"#{ENV["HOME"]}/.local/bin:$PATH\"\n")
    end
    rehash
  end

  def caveats
    <<~EOS
      Hermes Agent v#{version} installed via Homebrew! 🎉

      Next steps:
        source ~/.zshrc    # reload PATH (~/.local/bin is now on PATH)
        hermes setup      # run the interactive setup wizard

      Verify:
        hermes --version

      Config: #{etc/"hermes"}
      Data:   #{var/"hermes"}

      To update:
        brew upgrade hermes-agent

      Official docs: https://hermes-agent.nousresearch.com/docs/
    EOS
  end

  private

  def shell_configs
    home = Pathname.new(ENV["HOME"])
    configs = []
    configs << home/".zshrc" if (home/".zshrc").exist?
    configs << home/".bashrc" if (home/".bashrc").exist?
    configs << home/".bash_profile" if (home/".bash_profile").exist?
    configs
  end
end
