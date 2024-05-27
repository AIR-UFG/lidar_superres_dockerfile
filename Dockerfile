# Use the official ROS Noetic base image
FROM ros:noetic-ros-base

# Define the GitHub repository URL and project name as environment variables
ENV REPO_URL=https://github.com/macunaimaa/lidar_super_resolution_formiga.git
ENV PROJECT_NAME=SuperResolution
ENV HOME_DIR=/root
ENV ROOT_DIR=${HOME_DIR}/Documents/${PROJECT_NAME}

# Set the working directory to /home/ros_packages
WORKDIR /home/ros_packages

# Install necessary tools and dependencies including Python, visualization tools, TensorFlow, CUDA, and OpenCV
RUN apt-get update && apt-get install -y \
    git \
    python3 \
    python3-pip \
    python3-rosdep \
    python3-rosinstall \
    python3-vcstools \
    ros-noetic-rviz \
    software-properties-common \
    wget \
    gnupg2 \
    && rm -rf /var/lib/apt/lists/*

# Re-link python to ensure Python 3 is used
RUN ln -s /usr/bin/python3 /usr/bin/python

# Add NVIDIA package repositories for CUDA and cuDNN
RUN wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/cuda-ubuntu1804.pin && \
    mv cuda-ubuntu1804.pin /etc/apt/preferences.d/cuda-repository-pin-600 && \
    wget https://developer.download.nvidia.com/compute/cuda/11.4.2/local_installers/cuda-repo-ubuntu1804-11-4-local_11.4.2-470.57.02-1_amd64.deb && \
    dpkg -i cuda-repo-ubuntu1804-11-4-local_11.4.2-470.57.02-1_amd64.deb && \
    apt-key add /var/cuda-repo-ubuntu1804-11-4-local/7fa2af80.pub && \
    apt-get update && apt-get -y install cuda

# Install specific versions of TensorFlow and related dependencies to ensure compatibility
RUN pip3 install tensorflow==2.13.1 protobuf==3.20.3 grpcio==1.48.2 tensorboard==2.14.0

# Install OpenCV and numpy
RUN pip3 install opencv-python-headless numpy

# Initialize rosdep if not already initialized and update
RUN if [ ! -f /etc/ros/rosdep/sources.list.d/20-default.list ]; then \
      rosdep init; \
    fi && \
    rosdep update

# Create the project directory in the specific structure expected by the script
RUN mkdir -p ${ROOT_DIR}

# Copy folders weights and bags to the root directory
COPY weights ${ROOT_DIR}/weights
COPY bags ${ROOT_DIR}/../../bags

# Clone the GitHub repository into the src directory of the ROS workspace
RUN mkdir -p src && git clone ${REPO_URL} src/lidar_super_resolution

# Install all dependencies from the ROS workspace
RUN apt-get update && rosdep install --from-paths src --ignore-src -r -y && \
    rm -rf /var/lib/apt/lists/*

# Build the ROS workspace
RUN /bin/bash -c "source /opt/ros/noetic/setup.bash && catkin_make"

# Set environment variables to ensure paths are correctly set when the container starts
RUN echo "source /opt/ros/noetic/setup.bash" >> ~/.bashrc
RUN echo "source /home/ros_packages/devel/setup.bash" >> ~/.bashrc

# Source the setup.bash script when the container starts using entrypoint
ENTRYPOINT ["/bin/bash", "-c", "source /opt/ros/noetic/setup.bash && source /home/ros_packages/devel/setup.bash && exec \"$@\"", "--"]
CMD ["bash"]
