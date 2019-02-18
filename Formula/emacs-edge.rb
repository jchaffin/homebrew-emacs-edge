class EmacsEdge < Formula
  desc "GNU Emacs text editor"
  homepage "https://www.gnu.org/software/emacs/"
  url "https://github.com/jchaffin/emacs/archive/emacs-27.0.90.tar.gz"
  sha256 "d16b438abbbb43725419bec1a71c2754a28fa72908c553233e5a21fc9fc8e3c5"
  conflicts_with "emacs", :because => "Conflicting binaries"
  head "https://github.com/jchaffin/emacs.git"
   bottle do
    root_url "https://dl.bintray/jchaffin/emacs-edge"
    sha256 "5ff1775a5daa12597a6c218c585efa2725fd9221d877624b6ab118562dc41b3e" => :mojave
    rebuild 1
  end
  option "without-cocoa",
         "Build a non-Cocoa version of Emacs"
  option "without-dbus",
         "Build with d-bus support."
  option "without-modules",
         "Build with dynamic modules support."
  option "without-xml2",
          "Build without libxml2 support"
  option "without-gnutls",
          "Build without gnutls support"
  option "without-xwidgets",
         "Build without xwidget support."
  option "without-pdumper",
         "Build without portable dumper"
  option "without-imagemagick",
         "Build without imagemagick 7 support"
  # Opt in
  option "with-x11",
         "Build with x11 support"
  option "with-ctags",
         "Don't remove the ctags executable that emacs provides"
  option "with-modern-icon",
         "Use a modern style Emacs icon"

  depends_on "autoconf" => :build
  depends_on "gnu-sed" => :build
  depends_on "texinfo" => :build
  depends_on "automake" => :build
  depends_on "pkg-config" => :build
  depends_on "texinfo" => :build

  depends_on "little-cms2" => :recommended
  depends_on "dbus" => :recommended
  depends_on "gnutls" => :recommended
  depends_on "librsvg" => :recommended
  depends_on "imagemagick" => :recommended
  depends_on "mailutils" => :optional

  depends_on :x11 => :optional
  depends_on "libxml2" if build.with? "xml2"
  depends_on "glib" => :optional

  resource "modern-icon" do
    url "https://s3-us-west-1.amazonaws.com/emacs-edge/Emacs.icns.modern"
    sha256 "419a7ba22e6e03ef9e10c13dea59790becc5bebd1d0fb98982b3cacaa58b3b76"
  end

  if build.with? "x11"
      depends_on "freetype" => :recommended
      depends_on "fontconfig" => :recommended
  end

  if build.without? "cocoa"
    unless build.without? "xwidgets"
      odie "--with-xwidgets is supported only on cocoa via xwidget webkit"
    end
  end

  def install
    args = %W[
      --disable-dependency-tracking
      --disable-silent-rules
      --enable-locallisppath=#{HOMEBREW_PREFIX}/share/emacs/site-lisp
      --infodir=#{info}/emacs
      --prefix=#{prefix}
    ]

    unless build.without? "xml2"
      args << "--with-xml2"
    end
    if build.without? "dbus"
      args << "--without-dbus"
    else
      args << "--with-dbus"
    end
    unless build.without? "gnutls"
      args << "--with-gnutls"
    end
    unless build.without? "imagemagick"
      args << "--with-imagemagick"
    end
    unless build.without? "modules"
      args << "--with-modules"
    end
    unless build.without? "librsvg"
      args << "--with-rsvg"
    end
    unless build.without? "pdumper"
      args << "--with-pdumper"
    end
    unless build.without? "xwidgets"
     args << "--with-xwidgets"
    end
    args << "--without-pop" << "--with-mailutils" if build.with? "mailutils"


    if build.with? "cocoa"

      args << "--with-ns" << "--disable-ns-self-contained"

      ENV.prepend_path "PATH", Formula["gnu-sed"].opt_libexec/"gnubin"

      system "./autogen.sh"
      system "./configure", *args
      system "make"
      system "make", "install"

      icons_dir = buildpath/"nextstep/Emacs.app/Contents/Resources"

      if build.with? "modern-icon"
        rm "#{icons_dir}/Emacs.icns"
        resource("modern-icon").stage do
          icons_dir.install Dir["*.icns*"].first => "Emacs.icns"
        end
      end

      prefix.install "nextstep/Emacs.app"

      # Replace the symlink with one that avoids starting Cocoa.
      (bin/"emacs").unlink # Kill the existing symlink
      (bin/"emacs").write <<~EOS
        #!/bin/bash
        exec #{prefix}/Emacs.app/Contents/MacOS/Emacs "$@"
      EOS
    else
      if build.with? "x11"
        # These libs are not specified in xft's .pc. See:
        # https://trac.macports.org/browser/trunk/dports/editors/emacs/Portfile#L74
        # https://github.com/Homebrew/homebrew/issues/8156
        ENV.append "LDFLAGS", "-lfreetype -lfontconfig"
        args << "--with-x"
        args << "--with-gif=no" << "--with-tiff=no" << "--with-jpeg=no"
      else
        args << "--without-x"
      end
      args << "--without-ns"

      system "./configure", *args
      system "make"
      system "make", "install"
    end

    if build.without? "ctags"
      (bin/"ctags").unlink
      (share/man/man1/"ctags.1.gz").unlink
    end
  end

  plist_options manual: "emacs"

  def plist; <<~EOS
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
      <key>Label</key>
      <string>#{plist_name}</string>
      <key>ProgramArguments</key>
      <array>
        <string>#{opt_bin}/emacs</string>
        <string>--fg-daemon</string>
      </array>
      <key>RunAtLoad</key>
      <true/>
      <key>StandardOutPath</key>
      <string>/tmp/homebrew.mxcl.emacs-plus.stdout.log</string>
      <key>StandardErrorPath</key>
      <string>/tmp/homebrew.mxcl.emacs-plus.stderr.log</string>
    </dict>
    </plist>
    EOS
  end

  def caveats
    <<~EOS
      Emacs.app was installed to:
        #{prefix}

      To link the application:
        ln -s #{prefix}/Emacs.app /Applications
    EOS
  end
  test do
    assert_equal "4", shell_output("#{bin}/emacs --batch --eval=\"(print (+ 2 2))\"").strip
  end
end
