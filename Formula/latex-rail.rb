  # Documentation: https://docs.brew.sh/Formula-Cookbook
#                https://www.rubydoc.info/github/Homebrew/brew/master/Formula
# PLEASE REMOVE ALL GENERATED COMMENTS BEFORE SUBMITTING YOUR PULL REQUEST!
class LatexRail < Formula
  desc "Updated version of the LaTeX rail package for Syntax specification in EBNF (https://www.ctan.org/pkg/rail)"
  homepage "https://www.ctan.org/pkg/rail"
  url "https://github.com/Holzhaus/latex-rail/archive/v1.2.1.tar.gz"
  sha256 "081a9ec2af521f00f6ab99d2f07f8ba3a1bb03098f460a994682378ee46f6d43"
  # depends_on "cmake" => :build
  depends_on "bison"
  def install
    ENV.deparallelize  # if your formula fails when building in parallel
    # Remove unrecognized options if warned by configure
    # system "cmake", ".", *std_cmake_args
    inreplace "Makefile" do |s|
      s.gsub! '"-Dm"', "-m"
    end
    system "make", "PREFIX=#{prefix}", "TEXDIR=#{share}/texmf/tex/latex", "MANSUFFIX=1", "install"
    system "mktexlsr"
  end

  test do
    system bin/"rail", "--version"
    (testpath/"Test.tex").write<<-EOS.undent
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
    system "latex", testpath/"Test"
    assert_predicate testpath/"Test.rai", :exist?
    system bin/"rail", testpath/"Test"
    assert_predicate testpath/"Test.rao", :exist?
    system "latex", testpath/"Test"
    assert_predicate testpath/"Test.dvi", :exist?
  end
end

