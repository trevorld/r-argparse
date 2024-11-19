# Based on code from Dirk Eddelbuettel
# https://fosstodon.org/@eddelbuettel@mastodon.social/113499555242268476
get_linux_flavor <- function() {
    flavor <- NA_character_
    osrel <- "/etc/os-release"
    if (isTRUE(file.exists(osrel))) {   # on (at least) Debian, Ubuntu, Fedora
        x <- utils::read.table(osrel, sep = "=", row.names = 1L,
                               col.names = c("","Val"), header = FALSE)
        flavor <- tolower(x["ID", "Val"])
    }
    flavor
}
