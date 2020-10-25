FROM ubuntu:20.04

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update \
    && apt-get install -y build-essential cmake git wget libgl1-mesa-dev ssh vim gfortran libglib2.0-0 \
      libcurl4-openssl-dev libhdf5-dev libnetcdf-dev gdb \
      libnetcdf-c++4-dev dos2unix gdb \
    && rm -rf /var/lib/apt/lists/*

RUN wget http://repo.continuum.io/miniconda/Miniconda3-3.7.0-Linux-x86_64.sh -O ~/miniconda.sh \
   && bash ~/miniconda.sh -b -p $HOME/miniconda
ENV PATH /root/miniconda/bin:$PATH

# RUN git clone -b v5.6.3 --depth 1 https://code.qt.io/qt/qt5.git \
#     && cd qt5 \
#     && perl init-repository \
#     && ./configure -opensource -confirm-license -no-xcb -skip qtconnectivity \
#         -skip qt3d -skip qtactiveqt -skip qtandroidextras -skip qtcanvas3d -skip qtconnectivity \
#         -skip qtdeclarative -skip qtdoc -skip qtdocgallery -skip qtenginio -skip qtfeedback \
#         -skip qtgraphicaleffects -skip qtimageformats -skip qtlocation -skip qtmacextras \
#         -skip qtmultimedia -skip qtpim -skip qtpurchasing -skip qtqa -skip qtquick1 \
#         -skip qtquickcontrols -skip qtquickcontrols2 -skip qtrepotools -skip qtscript \
#         -skip qtsensors -skip qtserialbus -skip qtserialport -skip qtsvg -skip qtsystems \
#         -skip qttools -skip qttranslations -skip qtwayland -skip qtwebchannel -skip qtwebengine \
#         -skip qtwebkit -skip qtwebkit-examples -skip qtwebsockets -skip qtwebview -skip qtwinextras \
#     && make -j 2 \
#     && make install \
#     && cd .. \
#     && rm -rf qt5
# ENV PATH /usr/local/Qt-5.6.3/bin:$PATH

RUN wget https://dl.bintray.com/boostorg/release/1.65.1/source/boost_1_65_1.tar.gz \
    && tar xf boost_1_65_1.tar.gz \
    && echo "a13de2c8fbad635e6ba9c8f8714a0e6b4264b60a29b964b940a22554705b6b60  boost_1_65_1.tar.gz" | sha256sum -c --quiet \
    && rm boost_1_65_1.tar.gz \
    && cd boost_1_65_1 \
    && ./bootstrap.sh --prefix=/usr/local --with-libraries=filesystem,date_time,random,regex,log,chrono,system \
    && ./b2 cxxflags=-fPIC install \
    && cd /.. \
    && rm -rf boost_1_65_1
ENV BOOST_INCLUDEDIR=/usr/local/include

RUN wget https://github.com/google/googletest/archive/release-1.8.0.tar.gz \
   && tar xf release-1.8.0.tar.gz \
   && rm release-1.8.0.tar.gz \
   && cd googletest-release-1.8.0 \
   && mkdir build \
   && cd build \
   && cmake .. \
   && make \
   && make install \
   && cd ../.. \
   && rm -rf googletest-release-1.8.0

# Create a bamboo user and group (id 1000) so that we can run build as a non-root user on Bamboo.
RUN groupadd -g 1000 bamboo && useradd --no-log-init -m -u 1000 -g bamboo bamboo && chown 1000:1000 /home/bamboo

# Make conda useable from the bamboo user
RUN cp /root/miniconda.sh /home/bamboo && chown 1000:1000 /home/bamboo/miniconda.sh

USER bamboo
RUN bash /home/bamboo/miniconda.sh -b -p /home/bamboo/miniconda

ENV PATH /home/bamboo/miniconda/bin:$PATH

# Install required python packages
RUN conda install jinja2 docopt numpy --yes