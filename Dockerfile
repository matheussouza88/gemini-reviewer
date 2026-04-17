FROM node:24-alpine
RUN npm install -g @google/gemini-cli
# Bundle the instructions into the image for centralization
COPY PR_REVIEW.md /PR_REVIEW.md
ENTRYPOINT ["gemini"]
