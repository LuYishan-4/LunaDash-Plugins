import index from "../../../index.json";
import targets from "../../../contracts/targets.json";

export type Plugin = (typeof index.plugins)[number];
export type Target = (typeof targets)[number];

export const plugins = index.plugins as Plugin[];
export const targetList = targets as Target[];
export const targetMap = new Map(targetList.map(target => [target.id, target]));
