FROM sickcodes/docker-osx

WORKDIR /untangling-tools-benchmark

# Install development package requirements on the PATH
RUN /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" \
&& echo 'export PATH="/opt/homebrew/bin:$PATH"' >> ~/.bash_profile \
&& source ~/.bash_profile \
&& echo $PATH | tr ":" "\n"
# RUN brew install python@3.8 \
# && brew install pyenv \
# && pyenv install 3.8.15 \
# && pyenv global 3.8.15

RUN curl -s "https://get.sdkman.io" | bash 
RUN source "$HOME/.sdkman/bin/sdkman-init.sh"
RUN sdk install java 11.9.17-ms \
&& sdk install java 8.0.372-amzn 

RUN JAVA11_HOME = $(sdk home java 8.0.372-amzn) \
&& export PATH="${JAVA11_HOME}:$PATH"

# Install all Python modules and MacOS dependencies
COPY . .
RUN pip install -U -r requirements.txt \
&& brew install cpanminus \
&& brew install wget \
&& brew install coreutils

# Install Flexeme
WORKDIR /Flexeme
RUN git clone https://github.com/Thomsch/Flexeme /Flexeme

RUN brew install graphviz \
&& pip install pygraphviz

# Install Defects4J and Initialize it
WORKDIR /defects4j
RUN git clone https://github.com/rjust/defects4j /defects4j
RUN cpanm --installdeps . \
&& ./init.sh \
&& D4J_HOME="$(pwd)" \
&& export PATH="${D4J_HOME}/framework/bin:$PATH"

# Fill in environment variables
RUN cd /untangling-tools-benchmark \
&& echo "DEFECTS4J_HOME=${D4J_HOME}" > .env \
&& echo "JAVA_11=${JAVA11_HOME}/bin/java" >> .env

RUN export PYTHONHASHSEED=0
CMD ["./test/check_installation.sh"]