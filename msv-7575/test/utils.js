// Copied from https://github.com/ensuro/vaults/blob/main/test/utils.js
// TO DO: make a request to the maintainer of the package (a cool guy ;) to add this to the NPM package)
const ethers = require("ethers");

function encodeSwapConfig(swapConfig) {
  return ethers.AbiCoder.defaultAbiCoder().encode(["tuple(uint8, uint256, bytes)"], [swapConfig]);
}

function encodeDummyStorage({ failConnect, failDisconnect, failDeposit, failWithdraw }) {
  return ethers.AbiCoder.defaultAbiCoder().encode(
    ["tuple(bool, bool, bool, bool)"],
    [[failConnect || false, failDisconnect || false, failDeposit || false, failWithdraw || false]]
  );
}

function dummyStorage({ failConnect, failDisconnect, failDeposit, failWithdraw }) {
  return [failConnect || false, failDisconnect || false, failDeposit || false, failWithdraw || false];
}

const tagRegExp = new RegExp("\\[(?<neg>[!])?(?<variant>[a-zA-Z0-9]+)\\]", "gu");

function tagit(testDescription, test, only = false) {
  let any = false;
  const iit = only || this.only ? it.only : it;
  for (const m of testDescription.matchAll(tagRegExp)) {
    if (m === undefined) break;
    const neg = m.groups.neg !== undefined;
    any = any || !neg;
    if (m.groups.variant === this.name) {
      if (!neg) {
        // If tag found and not negated, run the it
        iit(testDescription, test);
        return;
      }
      // If tag found and negated, don't run the it
      return;
    }
  }
  // If no positive tags, run the it
  if (!any) iit(testDescription, test);
}

module.exports = {
  encodeDummyStorage,
  encodeSwapConfig,
  dummyStorage,
  tagit,
};
