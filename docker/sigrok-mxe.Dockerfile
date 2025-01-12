FROM debian:latest AS sigrok-mxe
LABEL \
	org.opencontainers.image.title="sigrok MXE Build Image" \	
	org.opencontainers.image.description="This image is used to cross compile the sigrok artefacts for Windows with MXE" \
	org.opencontainers.image.url="https://sigrok.org" \
	org.opencontainers.image.source="https://github.com/abraxa/sigrok-build" \
	org.opencontainers.image.licenses="GPL-3.0-or-later" \
	org.opencontainers.image.authors="Frank Stettner <frank-stettner@gmx.net>" \
	maintainer="Frank Stettner <frank-stettner@gmx.net>"

ENV BASE_DIR /opt
ENV MXE_DIR $BASE_DIR/mxe
ENV MXE_TARGETS "i686-w64-mingw32.static.posix x86_64-w64-mingw32.static.posix"
ENV MXE_PLUGIN_DIRS plugins/examples/qt5-freeze

RUN apt-get update \
	&& apt-get upgrade -y \
	&& apt-get install -y --no-install-recommends \
		sudo \
		autoconf \
		automake \
		autopoint \
		bash \
		bison \
		bzip2 \
		flex \
		g++ \
		g++-multilib \
		sdcc \
		gettext \
		git \
		gperf \
		gtk-doc-tools \
		intltool \
		libc6-dev-i386 \
		libgdk-pixbuf2.0-dev \
		libltdl-dev \
		libssl-dev \
		libtool-bin \
		libxml-parser-perl \
		lzip \
		make \
		openssl \
		p7zip-full \
		patch \
		perl \
		pkg-config \
		python3 \
		python-is-python3 \
		ruby \
		sed \
		unzip \
		wget \
		xz-utils \
		doxygen \
		nsis \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/*

WORKDIR $BASE_DIR
COPY mxe_fixes.patch $BASE_DIR
RUN git clone https://github.com/mxe/mxe.git $MXE_DIR \
	&& cd $MXE_DIR \
	&& git reset --hard b48b3cc7085548e896fe967dc6371ff9951390a4 \
	&& patch -p1 < $BASE_DIR/mxe_fixes.patch

RUN cd $MXE_DIR && make -j$(nproc) MXE_USE_CCACHE= DONT_CHECK_REQUIREMENTS=1 MXE_TARGETS="$MXE_TARGETS" MXE_PLUGIN_DIRS="$MXE_PLUGIN_DIRS" gcc
RUN cd $MXE_DIR && make -j$(nproc) MXE_USE_CCACHE= DONT_CHECK_REQUIREMENTS=1 MXE_TARGETS="$MXE_TARGETS" MXE_PLUGIN_DIRS="$MXE_PLUGIN_DIRS" glib
RUN cd $MXE_DIR && make -j$(nproc) MXE_USE_CCACHE= DONT_CHECK_REQUIREMENTS=1 MXE_TARGETS="$MXE_TARGETS" MXE_PLUGIN_DIRS="$MXE_PLUGIN_DIRS" \
		libzip \
		libusb1 \
		libftdi1

COPY hidapi_fixes.patch $BASE_DIR
RUN cd $MXE_DIR && patch -p1 < $BASE_DIR/hidapi_fixes.patch
RUN cd $MXE_DIR && make -j$(nproc) MXE_USE_CCACHE= DONT_CHECK_REQUIREMENTS=1 MXE_TARGETS="$MXE_TARGETS" MXE_PLUGIN_DIRS="$MXE_PLUGIN_DIRS" hidapi

RUN cd $MXE_DIR && make -j$(nproc) MXE_USE_CCACHE= DONT_CHECK_REQUIREMENTS=1 MXE_TARGETS="$MXE_TARGETS" MXE_PLUGIN_DIRS="$MXE_PLUGIN_DIRS" glibmm

RUN cd $MXE_DIR && make -j$(nproc) MXE_USE_CCACHE= DONT_CHECK_REQUIREMENTS=1 MXE_TARGETS="$MXE_TARGETS" MXE_PLUGIN_DIRS="$MXE_PLUGIN_DIRS" \
		qtbase \
		qtimageformats
RUN cd $MXE_DIR && make -j$(nproc) MXE_USE_CCACHE= DONT_CHECK_REQUIREMENTS=1 MXE_TARGETS="$MXE_TARGETS" MXE_PLUGIN_DIRS="$MXE_PLUGIN_DIRS" \
		qtsvg \
		qttools \
		qttranslations
RUN cd $MXE_DIR && make -j$(nproc) MXE_USE_CCACHE= DONT_CHECK_REQUIREMENTS=1 MXE_TARGETS="$MXE_TARGETS" MXE_PLUGIN_DIRS="$MXE_PLUGIN_DIRS" boost
RUN cd $MXE_DIR && make -j$(nproc) MXE_USE_CCACHE= DONT_CHECK_REQUIREMENTS=1 MXE_TARGETS="$MXE_TARGETS" MXE_PLUGIN_DIRS="$MXE_PLUGIN_DIRS" \
		check \
		gendef \
		libieee1284 \
		nettle \
		qwt \
		qtbase_CONFIGURE_OPTS='-no-sql-mysql'

RUN rm -rf $MXE_DIR/.log \
	&& rm -rf $MXE_DIR/mxe/pkg
