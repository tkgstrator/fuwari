ARG BUN_VERSION
ARG NODE_VERSION

FROM node:${NODE_VERSION} AS NODE
FROM oven/bun:${BUN_VERSION}

COPY --from=NODE /usr/local/bin/node /usr/local/bin/node
COPY --from=NODE /opt/yarn* /opt/yarn/

RUN ln -fs /usr/local/lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm
RUN ln -fs /usr/local/lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npx
RUN ln -fs /usr/local/lib/node /usr/local/bin/nodejs
RUN ln -fs /opt/yarn/bin/yarn /usr/local/bin/yarn
RUN ln -fs /opt/yarn/bin/yarn /usr/local/bin/yarnpkg

USER bun
WORKDIR /home/bun/app
CMD ["/bin/bash"]