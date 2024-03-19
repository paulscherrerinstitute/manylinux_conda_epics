ARG ARCH="x86_64"

FROM quay.io/pypa/manylinux_2_28_${ARCH}

ARG ARCH
ARG EPICS_VERSION="7.0.8"
ARG CONDA_DIR="/opt/conda"

ENV EPICS_HOST_ARCH=linux-${ARCH}
ENV EPICS_BASE="/opt/epics/base-${EPICS_VERSION}"
ENV PATH="${CONDA_DIR}/bin:$PATH"

# Build epics base and pcas
RUN mkdir /build;cd /build && \
    git clone https://github.com/epics-base/epics-base --branch R${EPICS_VERSION} --recursive -q epics-base && \
    git clone https://github.com/epics-modules/pcas epics-base/modules/pcas && \
    sed -i -E 's/(^[^#].*+= test.*$)/# \1/' \
        epics-base/Makefile \
        epics-base/modules/*/Makefile && \
    echo "GNU_DIR=$(dirname $(dirname $(which gcc)))" >> epics-base/configure/os/CONFIG_SITE.Common.linuxCommon && \
    echo -e "SUBMODULES += pcas\npcas_DEPEND_DIRS = libcom" > epics-base/modules/Makefile.local && \
    echo "INSTALL_LOCATION = ${EPICS_BASE}" > epics-base/configure/CONFIG_SITE.local && \
    make -C epics-base install && \
    cd /;rm -r /build

# Install miniconda
RUN curl -o miniconda.sh https://repo.anaconda.com/miniconda/Miniconda3-py310_24.1.2-0-Linux-${ARCH}.sh && \
    bash miniconda.sh -b -p ${CONDA_DIR} && \
    rm miniconda.sh

# Setup miniconda
RUN conda install conda-build && \
    conda clean --all --force-pkgs-dirs --yes

