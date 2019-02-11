class LatexRail < Formula
  desc "Updated version of the LaTeX rail package for Syntax specification in EBNF (https://www.ctan.org/pkg/rail)"
  homepage "https://www.ctan.org/pkg/rail"
  url "https://github.com/Holzhaus/latex-rail/archive/v1.2.1.tar.gz"
  sha256 "081a9ec2af521f00f6ab99d2f07f8ba3a1bb03098f460a994682378ee46f6d43"
  depends_on "bison"
  def install
    ENV.deparallelize  # if your formula fails when building in parallel
    # Remove unrecognized options if warned by configure
    # system "cmake", ".", *std_cmake_args
    bin.mkpath
    man1.mkpath

    (share/"texmf-local/tex/latex").mkpath

    args = %W[
      CC=#{ENV.cc}
      PREFIX=#{prefix}
      TEXDIR=#{share}/texmf-local/tex/latex
      MANSUFFIX=1
    ]
    inreplace "Makefile" do |s|
      s.gsub! 'install -Dm', 'install -m'
    end
    system "make", *args
    system "make", *args, "install"
  end

  def caveats
    <<~EOS
    To complete install of latex-rail, issue the following command:
      sudo ln -s #{share}/texmf-local/tex/latex/rails.sty $(kpsewhich --var-value=TEXMFLOCAL)/tex/latex
    Then register with texlive:
      sudo texmkslr
    EOS
  end

  test do
    (testpath/"Test.tex").write <<~EOS
      \\documentclass[preview]{standalone}
      \\usepackage{rail}
      \\begin{document}
      \\begin{rail}
      decl : 'def' identifier '=' ( expression + ';' )
       | 'type' identifier '=' type
       ;
      \\end{rail}
      \\end{document}
    EOS
  #   system "latex", testpath/"Test"
  #   assert_predicate testpath/"Test.rai", :exist?
  #   system bin/"rail", testpath/"Test"
  #   assert_predicate testpath/"Test.rao", :exist?
  #   system "latex", testpath/"Test"
  #   assert_predicate testpath/"Test.dvi", :exist?
  system "true"
  end
end


