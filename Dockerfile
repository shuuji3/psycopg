FROM python:3.12-bookworm
COPY . /app/
WORKDIR /app/docs/
RUN pip install -e "../psycopg[docs]" -e ../psycopg_pool

# Tmporary fix for Japanese font in ogp-social-cards
# TODO: switch back to the original package once the PR is merged:
# feat: allow specifying a custom font for the card text by shuuji3
# · Pull Request #110 · wpilibsuite/sphinxext-opengraph
# - https://github.com/wpilibsuite/sphinxext-opengraph/pull/110
RUN apt update && apt install fonts-noto-cjk
RUN pip install matplotlib
RUN pip install git+https://github.com/shuuji3/sphinxext-opengraph@feat/support-ogp-social-cards-font-option

CMD ["make", "serve"]
