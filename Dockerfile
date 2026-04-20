FROM node:22-alpine
RUN npm install -g @google/gemini-cli

# Bundle the instructions into the image for centralization
COPY PR_REVIEW.md /PR_REVIEW.md

# Bundle tools configuration to enable mcp-github and shell
RUN mkdir -p /root/.gemini
COPY projects.json /root/.gemini/projects.json

ENTRYPOINT ["gemini"]
