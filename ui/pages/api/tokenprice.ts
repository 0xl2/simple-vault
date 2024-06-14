import _ from "lodash";
import axios from "axios";
import type { NextApiRequest, NextApiResponse } from "next";

import { COINGECKO_URL, COINGECKO_HEADER } from "../../utils/const";

export default async function handler(
  req: NextApiRequest,
  res: NextApiResponse
) {
  if (req.method === "GET") {
    let { tokenid, timeLimit } = req.query;
    tokenid = tokenid ? tokenid.toString() : "";
    const timeLimitVal = timeLimit ? Number(timeLimit) : 30;
    if (tokenid.length > 0) {
      try {
        const priceResp = await axios.get(
          `${COINGECKO_URL}coins/${tokenid}/market_chart`,
          {
            headers: COINGECKO_HEADER,
            params: {
              vs_currency: "usd",
              days: timeLimitVal,
              interval: "daily",
            },
          }
        );
        const priceQuotes = _.get(priceResp, "data.prices");
        res.status(200).send(priceQuotes);
      } catch (e) {
        console.log(e);
        res.status(500).send("Server Error");
      }
    }
  }
}
