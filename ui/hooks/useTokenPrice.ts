import _ from "lodash";
import axios from "axios";
import { useCallback, useEffect, useState } from "react";

import { IToken } from "../utils/types";
import { showNotification, NotificationType } from "../utils/notification";

export const useTokenPrice = (token: IToken) => {
  const [prices, setPrices] = useState([]);

  const fetchPrices = useCallback(() => {
    axios
      .get(`api/tokenprice`, {
        params: {
          tokenid: token.id,
        },
      })
      .then((priceResp) => {
        const priceArr = _.get(priceResp, "data", []);

        const priceList = priceArr.map((priceItem: any) => [
          new Date(priceItem[0]),
          priceItem[1],
        ]);
        setPrices(priceList);
      })
      .catch((err) => {
        console.log(err, "err here");
        setPrices([]);
        showNotification("Token price fetching failed", NotificationType.ERROR);
      });
  }, [token]);

  useEffect(() => {
    fetchPrices();
  }, [token]);

  return { prices };
};
