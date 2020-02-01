library("argparse")
p <- ArgumentParser()
p$add_argument("-v", "--version", action = "version", version = "1.0.1")
p$parse_args("--version")
