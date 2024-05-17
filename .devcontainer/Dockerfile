FROM oven/bun:1.1.7
COPY --from=node:20.12.2 /usr/local/bin/node /usr/local/bin/node
COPY --from=node:20.12.2 /opt/yarn* /opt/yarn/

RUN ln -s /opt/yarn/bin/yarn /usr/local/bin/yarn
RUN ln -s /opt/yarn/bin/yarnpkg /usr/local/bin/yarnpkg

USER bun
WORKDIR /home/bun/app
CMD ["/bin/bash"]