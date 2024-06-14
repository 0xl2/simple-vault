import _ from "lodash";
import axios from "axios";
import type { NextApiRequest, NextApiResponse } from "next";

import { COINGECKO_URL, COINGECKO_HEADER } from "../../utils/const";

export default async function handler(
  req: NextApiRequest,
  res: NextApiResponse
) {
  if (req.method === "GET") {
    let { token } = req.query;
    token = token ? token.toString().toLowerCase() : "";
    if (token && token.length > 1) {
      try {
        const searchResp = await axios.get(`${COINGECKO_URL}search`, {
          headers: COINGECKO_HEADER,
          params: {
            query: token,
          },
        });
        const searchCoins = _.get(searchResp, "data.coins", []);

        const tokensResp = await axios.get(`${COINGECKO_URL}coins/list`, {
          headers: COINGECKO_HEADER,
          params: {
            include_platform: true,
          },
        });
        const tokens = _.get(tokensResp, "data");

        const tokenArr = searchCoins.map((coin: any) => {
          const contractAddr = tokens
            .map((tokenItem: any) =>
              tokenItem.id === coin.id
                ? _.get(tokenItem, "platforms.ethereum")
                : null
            )
            .find((addr: string) => addr !== null);

          return {
            id: coin.id,
            name: coin.name,
            symbol: coin.symbol,
            thumb: coin.thumb,
            address: contractAddr,
          };
        });
        res.status(200).send(tokenArr);
      } catch (e) {
        console.log(e);
        res.status(500).send("Server Error");
      }
    } else {
      res.status(500).send("Invalid search key");
    }
  }
}
