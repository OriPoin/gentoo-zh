# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="LXDE theme for IceWM"
HOMEPAGE="http://lxde.sf.net/"
SRC_URI="http://www.dok.lt/Baltix-Ubuntu-packages/baltix-2.6.x/lxde/${PN}.tar.bz2 -> ${P}.tar.bz2"

S="${WORKDIR}"
LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 ~ppc sparc ~x86"

RDEPEND="x11-wm/icewm"

src_unpack() {
	unpack ${A}
	cd "${S}"
	find . -name \.xvpics | xargs rm -rf
	find . -name \*~ | xargs rm -rf
	find . -name .svn | xargs rm -rf
}

src_install() {
	local ICEWM_THEMES=/usr/share/icewm/themes
	dodir "${ICEWM_THEMES}"
	cp -pR * "${D}/${ICEWM_THEMES}"
	chown -R root:0 "${D}/${ICEWM_THEMES}"
	rm -f "${D}/${ICEWM_THEMES}/Crus-IceWM/cpframes.sh" || die
	find "${D}/${ICEWM_THEMES}" -type d | xargs chmod 755 || die
	find "${D}/${ICEWM_THEMES}" -type f | xargs chmod 644 || die
}
