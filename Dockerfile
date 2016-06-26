FROM linuxbrew/linuxbrew
RUN brew install zsh
COPY ./brew-dep-tester.sh /home/linuxbrew
WORKDIR /home/linuxbrew
CMD ./brew-dep-tester.sh
    
