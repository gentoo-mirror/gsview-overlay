# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit bash-completion-r1 cmake git-r3

DESCRIPTION="Powerful map generator"
HOMEPAGE="https://gmt.soest.hawaii.edu/"
EGIT_REPO_URI="https://github.com/GenericMappingTools/gmt.git"
SRC_URI=""

LICENSE="GPL-2 gmttria? ( Artistic )"
SLOT="5"
IUSE="+dcw doc examples +fftw +gdal gmttria +gshhg lapack multislot openmp pcre pcre2 threads"

RDEPEND="
	!sci-biology/probcons
	app-text/ghostscript-gpl
	dcw? ( sci-geosciences/dcw-gmt )
	doc? ( dev-python/sphinx )
	doc? ( dev-python/sphinx-panels )
	fftw? ( sci-libs/fftw:3.0/3 )
	gdal? ( sci-libs/gdal )
	gshhg? ( sci-geosciences/gshhg-gmt )
	>=sci-libs/netcdf-4.1[hdf5]
	lapack? ( virtual/lapack )
	!multislot? ( !sci-geosciences/gmt:0 )
	pcre? ( dev-libs/libpcre )
	pcre2? ( dev-libs/libpcre2 )
	net-misc/curl
	sys-libs/zlib"

DEPEND="${RDEPEND}"

REQUIRED_USE="?? ( pcre pcre2 )"

src_configure() {
	local mycmakeargs=(
		-DLICENSE_RESTRICTED="$(usex gmttria no yes)"
		-DGMT_OPENMP="$(usex openmp)"
		-DGMT_USE_THREADS="$(usex threads)"
		-DGMT_INSTALL_TRADITIONAL_FOLDERNAMES=OFF # Install bash completions properly
		-DGMT_INSTALL_MODULE_LINKS=OFF # Don't install symlinks on gmt binary, they are conflicted with gmt4
		-DBASH_COMPLETION_DIR="$(get_bashcompdir)"
		-DGMT_DATADIR="share/${P}"
		-DGMT_DOCDIR="share/doc/${PF}"
		-DGMT_MANDIR="share/man"
	)
	use fftw || mycmakeargs+=( -DGMT_EXCLUDE_FFTW3=yes )
	use gdal || mycmakeargs+=( -DGMT_EXCLUDE_GDAL=yes )
	use lapack || mycmakeargs+=( -DGMT_EXCLUDE_LAPACK=yes )
	use pcre || mycmakeargs+=( -DGMT_EXCLUDE_PCRE=yes )
	use pcre2 || mycmakeargs+=( -DGMT_EXCLUDE_PCRE2=yes )
	cmake_src_configure
}

src_compile() {
	cmake_src_compile
	pushd "${BUILD_DIR}" || die
	if use doc; then
		make -j1 docs_html || die
		make -j1 docs_man || die

		if use multislot; then
			# Rename man pages to avoid a name conflict with gmt4
			pushd doc/rst/man/1 || die
			local m c suffix newc
			for m in *.gz; do
				c=${m%%.*}
				suffix=${m#*.}
				newc=gmt_${c}
				# This man pages does'nt conflict
				case "${c}" in
				"gmt" | "gmt.conf" | "postscriptlight")
					continue ;;
				"gmt_shell_functions")
					newc=gmt5_shell_functions ;;
				"gmtcolors")
					newc=gmt5colors ;;
				esac
				mv "${c}.${suffix}" "${newc}.${suffix}" || die
			done
			popd || die
		fi
	fi
	popd || die
}

src_install() {
	cmake_src_install

	if use examples; then
		docompress -x /usr/share/doc/${PF}/examples
	else
		rm -rf "${ED}/usr/share/doc/${PF}/examples" || die
	fi

	if ! use doc; then
		rm -rf "${ED}/usr/share/doc/${PF}/html" || die
	fi

	# Decompress manuals
	if use doc; then
		find "${ED}/usr/share/man" -name "*.gz" -exec gunzip {} + || die
	fi

	if use multislot; then
		# Rename some files to avoid a name conflict with gmt4
		mv "${ED}/usr/bin/gmt_shell_functions.sh" "${ED}/usr/bin/gmt5_shell_functions.sh" || die
		mv "${ED}/usr/bin/isogmt" "${ED}/usr/bin/isogmt5" || die
	fi

	rm "${ED}/usr/bin/gmtswitch" || die
	# Rename bash completion file
	echo mv "${D}$(get_bashcompdir)/gmt_completion.bash" "${D}/$(get_bashcompdir)/gmt"
	mv "${D}$(get_bashcompdir)/gmt_completion.bash" "${D}$(get_bashcompdir)/gmt" || die
}
