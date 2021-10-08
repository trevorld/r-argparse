desc "Build files for packaging"
task :default do
    sh 'rst2html README.rst README.html'
    sh 'pandoc -t markdown_strict -o README.md README.rst'
    sh 'Rscript -e "pkgdown::build_site()"'
end
