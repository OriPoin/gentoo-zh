# Copyright 2021-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cmake-multilib multibuild

DESCRIPTION="A cross-platform (C99/C++11) process library"
HOMEPAGE="https://github.com/DaanDeMeyer/reproc"
SRC_URI="https://github.com/DaanDeMeyer/reproc/archive/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="MIT"
SLOT="0/14"
KEYWORDS="~amd64 ~arm64 ~x86"
IUSE="test static-libs"
RESTRICT="test"

PATCHES=(
	"${FILESDIR}/reproc-14.2.5-static.patch"
)

pkg_setup() {
	if use static-libs;then
		MULTIBUILD_VARIANTS=( shared static )
	else
		MULTIBUILD_VARIANTS=( shared )
	fi
}

multilib_src_configure() {
	local mycmakeargs=(
		-DCMAKE_BUILD_TYPE=Release
		-DCMAKE_INSTALL_PREFIX="${EPREFIX}"/usr
		-DCMAKE_INSTALL_LIBDIR=$(get_libdir)
		-DBUILD_SHARED_LIBS=ON
		-DREPROC++=ON
		-DREPROC_TEST=$(usex test)
	)

	case "${MULTIBUILD_ID}" in
		static-*)
			mycmakeargs+=(
				-DBUILD_SHARED_LIBS=OFF
			)
			;;
		shared-*)
			mycmakeargs+=(
				-DBUILD_SHARED_LIBS=ON
			)
			;;
		*)
			die "${MULTIBUILD_ID%-*} link type not implemented in this ebuild"
			;;
	esac

	cmake_src_configure
}


src_configure() {
	multibuild_foreach_variant cmake-multilib_src_configure
}

src_compile() {
	multibuild_foreach_variant cmake-multilib_src_compile
}

src_test() {
	multibuild_foreach_variant cmake-multilib_src_test
}

src_install() {
	multibuild_foreach_variant cmake-multilib_src_install
}

