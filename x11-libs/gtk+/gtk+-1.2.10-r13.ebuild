# Copyright 1999-2015 Gentoo Foundation
# Copyright 2016-2023 Michael Uleysky
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit autotools flag-o-matic toolchain-funcs multilib-minimal

DESCRIPTION="The GIMP Toolkit"
HOMEPAGE="http://www.gtk.org/"
SRC_URI="mirror://gnome/sources/${PN}/$(ver_cut 1-2)/${PN}-${PV}.tar.gz"

LICENSE="LGPL-2.1+"
SLOT="1"
KEYWORDS="alpha amd64 arm arm64 hppa ia64 ~mips ppc ppc64 ~sh sparc x86 ~x86-fbsd"
IUSE="nls debug"

# Supported languages and translated documentation
# Be sure all languages are prefixed with a single space!
MY_AVAILABLE_LINGUAS=" az ca cs da de el es et eu fi fr ga gl hr hu it ja ko lt nl nn no pl pt_BR pt ro ru sk sl sr sv tr uk vi"
IUSE="${IUSE} ${MY_AVAILABLE_LINGUAS// / linguas_}"

RDEPEND=">=dev-libs/glib-1.2.10-r6:1[${MULTILIB_USEDEP}]
	>=x11-libs/libX11-1.5.0-r1[${MULTILIB_USEDEP}]
	>=x11-libs/libXext-1.3.1-r1[${MULTILIB_USEDEP}]
	>=x11-libs/libXi-1.7.2[${MULTILIB_USEDEP}]
	>=x11-libs/libXt-1.1.4[${MULTILIB_USEDEP}]"
DEPEND="${RDEPEND}
	x11-base/xorg-proto
	nls? ( sys-devel/gettext dev-util/intltool )"
PDEPEND="x11-themes/gtk-engines:1"

MULTILIB_CHOST_TOOLS=(/usr/bin/gtk-config)

PATCHES=(
	"${FILESDIR}/${P}-m4.patch"
	"${FILESDIR}/${P}-automake.patch"
	"${FILESDIR}/${P}-cleanup.patch"
	"${FILESDIR}/${P}-r8-gentoo.diff"
	"${FILESDIR}/${PN}-1.2-locale_fix.patch"
	"${FILESDIR}/${P}-as-needed.patch"
	"${FILESDIR}/${P}-automake-1.13.patch" #467520
	"${FILESDIR}/${P}-undef.patch"
)

src_prepare() {
	default
	append-cflags -std=gnu89
	sed -i '/libtool.m4/,/AM_PROG_NM/d' acinclude.m4 #168198
	mv configure.in configure.ac || die
	eautoreconf
}

multilib_src_configure() {
	local myconf=
	use nls || myconf="${myconf} --disable-nls"
	strip-linguas ${MY_AVAILABLE_LINGUAS}

	if use debug ; then
		myconf="${myconf} --enable-debug=yes"
	else
		myconf="${myconf} --enable-debug=minimum"
	fi

	ECONF_SOURCE="${S}" \
	econf \
		--disable-static \
		--sysconfdir="${EPREFIX}"/etc \
		--with-xinput=xfree \
		--with-x \
		${myconf} \
		GLIB_CONFIG="/usr/bin/${CHOST}-glib-config"
}

multilib_src_install_all() {
	einstalldocs
	docinto docs
	cd docs
	dodoc *.txt *.gif text/*
	dodoc -r html

	#install nice, clean-looking gtk+ style
	insinto /usr/share/themes/Gentoo/gtk
	doins "${FILESDIR}"/gtkrc
}

pkg_postinst() {
	if [[ -e /etc/X11/gtk/gtkrc ]] ; then
		ewarn "Older versions added /etc/X11/gtk/gtkrc which changed settings for"
		ewarn "all themes it seems.  Please remove it manually as it will not due"
		ewarn "to /env protection."
	fi

	echo ""
	einfo "The old gtkrc is available through the new Gentoo gtk theme."
}
