import { toast } from "react-toastify";

export enum NotificationType {
  ERROR,
  SUCCESS,
}

const ColorStyle = {
  [NotificationType.ERROR]: {
    background: "red",
    color: "white",
  },
  [NotificationType.SUCCESS]: {
    background: "green",
    color: "white",
  },
};

export function showNotification(message: string, type: NotificationType) {
  return toast(message, {
    autoClose: 3000,
    style: {
      ...ColorStyle[type],
    },
  });
}
