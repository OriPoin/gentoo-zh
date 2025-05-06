# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cmake-multilib multibuild

DESCRIPTION="YAML parser and emitter in C++"
HOMEPAGE="https://github.com/jbeder/yaml-cpp"
SRC_URI="https://github.com/jbeder/yaml-cpp/archive/refs/tags/${PV}.tar.gz -> ${P}.gh.tar.gz"

LICENSE="MIT"
SLOT="0/0.8"
KEYWORDS="~amd64 ~arm ~arm64 ~hppa ~loong ~ppc ~ppc64 ~riscv ~sparc ~x86 ~amd64-linux ~x86-linux"
IUSE="test static-libs"
RESTRICT="!test? ( test )"

DEPEND="
	test? ( dev-cpp/gtest[${MULTILIB_USEDEP}] )
"

PATCHES=(
	"${FILESDIR}/yaml-cpp-0.8.0-gtest.patch"
	"${FILESDIR}/yaml-cpp-0.8.0-gcc13.patch"
	"${FILESDIR}/yaml-cpp-0.8.0-include-cstdint.patch"
	"${FILESDIR}/yaml-cpp-0.8.0-pkgconfig.patch"
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
		-DYAML_CPP_BUILD_TOOLS=OFF # Don't have install rule
		-DYAML_CPP_BUILD_TESTS=$(usex test)
	)
	case "${MULTIBUILD_ID}" in
		static-*)
			mycmakeargs+=(
				-DYAML_BUILD_SHARED_LIBS=OFF
				-DYAML_CPP_PKG_CONFIG_NAME="yaml-cpp-static"
			)
			;;
		shared-*)
			mycmakeargs+=(
				-DYAML_BUILD_SHARED_LIBS=ON
				-DYAML_CPP_PKG_CONFIG_NAME="yaml-cpp"
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
