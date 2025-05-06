# Copyright 2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

#DISTUTILS_USE_PEP517=no
DISTUTILS_EXT=1
DISTUTILS_OPTIONAL=1
DISTUTILS_SINGLE_IMPL=1
PYTHON_COMPAT=( python3_{10..12} )

inherit distutils-r1 cmake multilib

DATE_TAG="2024.12.12"

DESCRIPTION="The Fast Cross-Platform Package Manager"
HOMEPAGE="https://github.com/mamba-org/mamba"
S="${WORKDIR}/${PN}-${P}"
SRC_URI="https://github.com/mamba-org/mamba/archive/refs/tags/${DATE_TAG}.tar.gz -> ${P}.tar.gz"

LICENSE="BSD"
SLOT="0/2"
KEYWORDS="~amd64"
IUSE="python micromamba"
# PROPERTIES="test_network"
RESTRICT="test"
REQUIRED_USE="python? ( ${PYTHON_REQUIRED_USE} )"

DEPEND="app-arch/libarchive:=
	app-arch/zstd:=
	dev-cpp/cli11
	dev-cpp/nlohmann_json
	dev-cpp/reproc:=
	dev-cpp/tl-expected
	dev-cpp/yaml-cpp
	dev-libs/simdjson
	sys-libs/libsolv:=[conda]
	micromamba? (
		app-crypt/mit-krb5[static-libs]
		app-arch/bzip2[static-libs]
		app-arch/libarchive[static-libs]
		app-arch/lz4[static-libs]
		app-arch/xz-utils[static-libs]
		app-arch/zstd[static-libs]
		dev-cpp/yaml-cpp:=[static-libs]
		dev-cpp/reproc:=[static-libs]
		dev-libs/libunistring[static-libs]
		dev-libs/simdjson[static-libs]
		net-dns/libidn2[static-libs]
		net-libs/libssh2[static-libs]
		net-libs/libpsl[static-libs]
		net-libs/nghttp2[static-libs]
		net-libs/nghttp3[static-libs]
		net-dns/c-ares[static-libs]
		net-misc/curl[static-libs]
		sys-apps/acl[static-libs]
		sys-fs/e2fsprogs[static-libs]
		sys-libs/libsolv:=[static-libs]
		sys-libs/zlib[static-libs]
		)
	dev-libs/libfmt:=
	dev-libs/spdlog
	net-misc/curl
	python? ( ${PYTHON_DEPS} )
"
# conflict to micromamba from benzene-overlay
RDEPEND="${DEPEND}
	!dev-util/micromamba-bin
	!dev-util/micromamba
"
BDEPEND="
	python? (
		${PYTHON_DEPS}
		${DISTUTILS_DEPS}
		$(python_gen_cond_dep 'dev-python/pybind11[${PYTHON_USEDEP}]')
		$(python_gen_cond_dep 'dev-python/scikit-build[${PYTHON_USEDEP}]')
	)
"
#	test? (
#		app-shells/dash
#		app-shells/tcsh
#		app-shells/zsh
#		$(python_gen_cond_dep '
#			dev-python/pytest-lazy-fixture[${PYTHON_USEDEP}]
#			dev-python/pytest-xprocess[${PYTHON_USEDEP}]
#		')
#	)

S="${WORKDIR}/${PN}-${DATE_TAG}"

# distutils_enable_tests pytest

# EPYTEST_IGNORE=(
	# No module named 'conda_package_handling'
	# Depends on dev-python/zstandard[${PYTHON_USEDEP}]
#	micromamba/tests/test_package.py
# )

PATCHES=(
        "${FILESDIR}/mamba-static.patch"
)

src_prepare() {
	cmake_src_prepare
	use python && { sed -i \
		"s|\${CMAKE_CURRENT_SOURCE_DIR}|\${CMAKE_INSTALL_PREFIX}\/$(python_get_sitedir | sed -e 's|/usr/||')|" \
		libmambapy/CMakeLists.txt || die ; pushd libmambapy || die ; distutils-r1_src_prepare ;
	}
}

src_configure() {
	cat > "${T}"/zstdConfig.cmake <<-EOF || die
		add_library(zstd::libzstd_shared SHARED IMPORTED)
		set_target_properties(zstd::libzstd_shared PROPERTIES
			IMPORTED_LOCATION "${EPREFIX}/usr/$(get_libdir)/libzstd$(get_libname)")
	EOF
	local mycmakeargs=(
		-DCMAKE_BUILD_TYPE=Release
		-DCMAKE_INSTALL_PREFIX="${EPREFIX}/usr"
		-DCMAKE_POSITION_INDEPENDENT_CODE=ON
		-DBUILD_LIBMAMBA=ON
		-DBUILD_LIBMAMBAPY=$(usex python)
		-DBUILD_LIBMAMBA_TESTS=NO
		-DBUILD_MAMBA_PACKAGE=OFF
		-DBUILD_MICROMAMBA=$(usex micromamba)
		-DBUILD_SHARED=ON
		-DBUILD_STATIC=OFF
		-Dzstd_DIR="${T}"
	)
	if use micromamba; then
		cat > "${T}"/LibsolvConfig.cmake <<-EOF || die
			add_library(solv::libsolv_static STATIC IMPORTED)
			set_target_properties(solv::libsolv_static PROPERTIES
					IMPORTED_LOCATION "${EPREFIX}/usr/$(get_libdir)/libsolv.a")
			add_library(solv::libsolvext_static STATIC IMPORTED)
			set_target_properties(solv::libsolvext_static PROPERTIES
					IMPORTED_LOCATION "${EPREFIX}/usr/$(get_libdir)/libsolv.a")
			add_library(solv::libsolv SHARED IMPORTED)
			set_target_properties(solv::libsolv PROPERTIES
					IMPORTED_LOCATION "${EPREFIX}/usr/$(get_libdir)/libsolvext$(get_libname)")
			add_library(solv::libsolvext SHARED IMPORTED)
			set_target_properties(solv::libsolvext PROPERTIES
					IMPORTED_LOCATION "${EPREFIX}/usr/$(get_libdir)/libsolvext$(get_libname)")
		EOF
		cat > "${T}"/reprocConfig.cmake <<-EOF || die
			add_library(reproc_static STATIC IMPORTED)
			set_target_properties(reproc_static PROPERTIES
					IMPORTED_LOCATION "${EPREFIX}/usr/$(get_libdir)/libreproc.a")
			add_library(reproc++_static STATIC IMPORTED)
			set_target_properties(reproc++_static PROPERTIES
					IMPORTED_LOCATION "${EPREFIX}/usr/$(get_libdir)/libreproc++.a")
			add_library(reproc SHARED IMPORTED)
			set_target_properties(reproc PROPERTIES
					IMPORTED_LOCATION "${EPREFIX}/usr/$(get_libdir)/libreproc$(get_libname)")
			add_library(reproc++ SHARED IMPORTED)
			set_target_properties(reproc++ PROPERTIES
					IMPORTED_LOCATION "${EPREFIX}/usr/$(get_libdir)/libreproc++$(get_libname)")
		EOF
		cat > "${T}"/simdjsonConfig.cmake <<-EOF || die
			add_library(simdjson::simdjson_static STATIC IMPORTED)
			set_target_properties(simdjson::simdjson_static PROPERTIES
					IMPORTED_LOCATION "${EPREFIX}/usr/$(get_libdir)/libsimdjson_static.a")
			add_library(simdjson::simdjson SHARED IMPORTED)
			set_target_properties(simdjson::simdjson PROPERTIES
					IMPORTED_LOCATION "${EPREFIX}/usr/$(get_libdir)/libsimdjson$(get_libname)")
		EOF
		cat > "${T}"/yaml-cppConfig.cmake <<-EOF || die
			add_library(yaml-cpp::yaml-cpp_static STATIC IMPORTED)
			set_target_properties(yaml-cpp::yaml-cpp_static PROPERTIES
					IMPORTED_LOCATION "${EPREFIX}/usr/$(get_libdir)/libyaml-cpp.a")
			add_library(yaml-cpp::yaml-cpp SHARED IMPORTED)
			set_target_properties(yaml-cpp::yaml-cpp PROPERTIES
					IMPORTED_LOCATION "${EPREFIX}/usr/$(get_libdir)/libyaml-cpp$(get_libname)")
		EOF
		mycmakeargs+=(
			-Dyaml-cpp_DIR="${T}" \
			-Dreproc_DIR="${T}" \
			-Dreproc++_DIR="${T}" \
			-Dsimdjson_DIR="${T}"
		)
	fi
	cmake_src_configure
}

src_compile() {
	cmake_src_compile
	if use python; then
		cmake --install ${BUILD_DIR} --prefix ${T}
		cd libmambapy || die
		export SKBUILD_CONFIGURE_OPTIONS="\
		-DCMAKE_BUILD_WITH_INSTALL_RPATH=ON \
		-DBUILD_LIBMAMBA=ON \
		-DBUILD_LIBMAMBAPY=ON \
		-DBUILD_MICROMAMBA=OFF \
		-DBUILD_MAMBA_PACKAGE=OFF \
		-Dlibmamba_ROOT=${T}"
		distutils-r1_src_compile
	fi
}

src_install() {
	cmake_src_install
	if use python; then
		cd libmambapy || die
		distutils-r1_src_install
	fi
}
