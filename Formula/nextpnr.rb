class Nextpnr < Formula
  desc "Place and Route Tool for FPGAs"
  homepage "https://github.com/YosysHQ/nextpnr"
  url "https://github.com/YosysHQ/nextpnr/archive/ced31aa917d2b9da711f246815aae0d968b9365a.tar.gz"
  version "20210509"
  sha256 "8f4aba491ee6e1ff15b444e1628dac28a2f1943a371aa269126bcd937eeb30b7"
  head "https://github.com/YosysHQ/nextpnr.git"

  option "with-gui", "Enable GUI"
  option "without-python", "No python scripting support"
  option "with-static", "Build with static libraries"
  option "with-arch-generic", "Enable generic arch support"
  option "without-arch-ice40", "Disable support for Lattice iCE40 FPGAs"
  option "without-arch-ecp5", "Disable support for Lattice ECP5 FPGAs"
  option "without-arch-nexus", "Disable support for Lattice Nexus FPGAs"

  depends_on "cmake" => :build
  depends_on "ninja" => :build

  depends_on "boost"
  depends_on "boost-python3"
  depends_on "eigen"
  depends_on "icestorm" if build.with? "arch-ice40"
  depends_on "prjtrellis" if build.with? "arch-ecp5"
  depends_on "prjoxide" if build.with? "arch-nexus"
  depends_on "qt5" if build.with? "gui"
  depends_on "python" if build.with? "python"

  resource "abseil-cpp" do
   url "https://github.com/abseil/abseil-cpp/archive/a76698790753d2ec71f655cdc84d61bcb27780d4.tar.gz"
   sha256 "c7862d3fd133504a401140894763ac9e9456c1c901bba37e1bc659854599befb"
  end

  resource "fpga-interchange-schema" do
   url "https://github.com/SymbiFlow/fpga-interchange-schema/archive/b3ab09776c8dc31a71ca2c7fbcb4575219232d16.tar.gz"
   sha256 "0b8ebb7c5144b5bd2eb4153058aebd7918ac6a1cae765baa8ea82a81e343cb49"
  end

  def install
    (buildpath/"3rdparty/abseil-cpp").install resource("abseil-cpp") unless build.head?
    (buildpath/"3rdparty/fpga-interchange-schema").install resource("fpga-interchange-schema") unless build.head?

    # Generic options
    args = []
    args << "-DBUILD_GUI=ON" if build.with? "gui"
    args << "-DBUILD_PYTHON=OFF" if build.without? "python"
    args << "-DSTATIC_BUILD=ON" if build.with? "static"

    # Architectures
    archs = []

    # ICE40
    archs << "ice40" if build.with? "arch-ice40"
    args << "-DICESTORM_INSTALL_PREFIX=#{Formula["icestorm"].opt_prefix}" if build.with? "arch-ice40"

    # ECP5
    archs << "ecp5" if build.with? "arch-ecp5"
    args << "-DTRELLIS_INSTALL_PREFIX=#{Formula["prjtrellis"].opt_prefix}" if build.with? "arch-ecp5"

    # Nexus
    archs << "nexus" if build.with? "arch-nexus"
    args << "-DOXIDE_INSTALL_PREFIX=#{Formula["prjoxide"].opt_prefix}" if build.with? "arch-nexus"

    # Generic
    archs << "generic" if build.with? "arch-generic"

    args << ("-DARCH=" << archs.join(";"))

    # Version information
    stable_version_commit = @stable.url[/([a-f0-9]{8})[a-f0-9]{32}\.tar\.gz/,1]
    stable_version = @stable.version.to_s+" ("+stable_version_commit+")"
    args << "-DCURRENT_GIT_VERSION="+stable_version unless build.head?
    args << "-DCURRENT_GIT_VERSION="+head.version.commit if build.head?

    system "cmake", *args, ".", "-GNinja", *std_cmake_args
    system "ninja"
    system "ninja", "install"
  end

  test do
    system "#{bin}/nextpnr-ice40", "--help" if build.with? "arch-ice40"
    system "#{bin}/nextpnr-ecp5", "--help" if build.with? "arch-ecp5"
    system "#{bin}/nextpnr-nexus", "--help" if build.with? "arch-nexus"
  end
end
