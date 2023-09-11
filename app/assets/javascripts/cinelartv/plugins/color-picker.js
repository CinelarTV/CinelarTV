import "@melloware/coloris/dist/coloris.css";
import Coloris from "@melloware/coloris";

window.coloris = Coloris({
    el: "#color-picker",
})

Coloris.init();



let ColorPicker = Coloris

export default ColorPicker;