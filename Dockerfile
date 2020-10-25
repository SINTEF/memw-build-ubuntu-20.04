FROM ubuntu:20.04

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update \
    && apt-get install -y build-essential cmake git wget ssh vim gfortran libglib2.0-0 \
      libcurl4-openssl-dev libhdf5-dev libnetcdf-dev gdb \
      libnetcdf-c++4-dev dos2unix \
    && rm -rf /var/lib/apt/lists/*

RUN wget https://repo.anaconda.com/miniconda/Miniconda3-py37_4.8.3-Linux-x86_64.sh -O ~/miniconda.sh \
   && bash ~/miniconda.sh -b -p $HOME/miniconda
ENV PATH /root/miniconda/bin:$PATH

RUN wget https://dl.bintray.com/boostorg/release/1.74.0/source/boost_1_74_0.tar.gz \
    && tar xf boost_1_74_0.tar.gz \
    && echo "afff36d392885120bcac079148c177d1f6f7730ec3d47233aa51b0afa4db94a5  boost_1_74_0.tar.gz" | sha256sum -c --quiet \
    && rm boost_1_74_0.tar.gz \
    && cd boost_1_74_0 \
    && ./bootstrap.sh --prefix=/usr/local --with-libraries=filesystem,date_time,random,regex,log,chrono,system \
    && ./b2 cxxflags=-fPIC install \
    && cd /.. \
    && rm -rf boost_1_74_0
ENV BOOST_INCLUDEDIR=/usr/local/include

RUN wget https://github.com/google/googletest/archive/release-1.10.0.tar.gz \
   && tar xf release-1.10.0.tar.gz \
   && rm release-1.10.0.tar.gz \
   && cd googletest-release-1.10.0 \
   && mkdir build \
   && cd build \
   && cmake .. \
   && make \
   && make install \
   && cd ../.. \
   && rm -rf googletest-release-1.10.0

# Create a bamboo user and group (id 1000) so that we can run build as a non-root user on Bamboo.
RUN groupadd -g 1000 bamboo && useradd --no-log-init -m -u 1000 -g bamboo bamboo && chown 1000:1000 /home/bamboo

# Make conda useable from the bamboo user
RUN cp /root/miniconda.sh /home/bamboo && chown 1000:1000 /home/bamboo/miniconda.sh

USER bamboo
RUN bash /home/bamboo/miniconda.sh -b -p /home/bamboo/miniconda

ENV PATH /home/bamboo/miniconda/bin:$PATH

# Install required python packages
RUN conda install jinja2 docopt numpy --yes