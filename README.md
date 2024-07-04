# Tokenized Vault Competition @ ETHCC
## Resources to get Started

### Boilerplate
[Awesome foundry - list of tools for foundry](https://github.com/crisgarner/awesome-foundry)

### ERC4626

[​ERC-4626](https://eips.ethereum.org/EIPS/eip-4626)
[Reference Implementation of 4626](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/extensions/ERC4626.sol)

### ERC7535

​[ERC-7535](https://eips.ethereum.org/EIPS/eip-7535)

### ERC7540
​[ERC-7540](https://eips.ethereum.org/EIPS/eip-7540)
[Reference Interface of 7540](https://github.com/centrifuge/liquidity-pools/blob/main/src/interfaces/IERC7540.sol)
[Reference Implementation of 7540](https://github.com/centrifuge/liquidity-pools/blob/main/src/ERC7540Vault.sol)

### ERC7575
[ERC-7575](https://eips.ethereum.org/EIPS/eip-7575)
[Reference Interface of 7575](https://github.com/centrifuge/liquidity-pools/blob/main/src/interfaces/IERC7575.sol)
[Reference Implementation of 7575](https://github.com/centrifuge/liquidity-pools/blob/main/src/token/Tranche.sol)

[Super Vaults - Example 4626 wrapped vaults](https://github.com/superform-xyz/super-vaults)


## Event general information and bounties

[Tokenized Vault Competition @ ETHCC](https://lu.ma/smo8wv09?tk=orTIsj)

**You need to submit yourself as attending to be considered a valid contestant. We will use this email to submit you important information during the competition and communicate closer and after the deadline!**

## Event rules 
The event officially starts on `Thursday, the 4th of July 2024, at 8.00pm UTC +0`

You are expected to perform work on your projects and ideas until the submission deadline.

Submission deadline is `Thursday, the 11th of July 2024, at 8.00pm UTC +0`. Any submissions received or with new commited work past this point will be welcomed, but won't be eligible to present on `Friday, the 12th of July 2024`, nor to receive any top prize (but may earn a participation prize). The timestamp of submission will be taken from the last valid commit in an open pull request to the `vault-bounties`.

Projects must be built on top of existing libraries, boilerplates or reference implementations. Projects that are ported from other existing application will be disqualified.

By participating, you are acknowledging that you need to present your work in the [Tokenized Vault Competition @ ETHCC](https://lu.ma/smo8wv09?tk=orTIsj) event, either in `TheMerode` in person, or remotely. Notice that an online standup will be made friday morning with online contestants that intend to present in a separate presentation link. In this link you can test that your connection is good and that you indeed confirm you will be presenting. This process will take a maximum of 1 minute per submission.

**Not presenting is automatically not eligible to receive any top prize.**

Guidelines on how to present will be provided closer or right after the deadline of submission, but presentations are expected to be small (few minutes) and mostly showcase a live go-through the codebase with some Q/A at the end. We will inform near this deadline the exact amount of minutes you can take to present (notice that a clock will be used to count for this). Note that you must have Zoom installed to participate in the online session.

The minimum to be able to participate is to mark yourself as attending the lu.ma event and submit a project as described in the below sections.

You may participate in a team, but presentations will be single person only (a member of the team has to be chosen as the presento)


## Content of your project
In your codebase it is only expected to be found foundry boilerplate, any required libs, your source code and a README file.

The README MUST contain the following minimum content:
- `Unique subbmission name`. We will use this submission name to identify your project, award it with prizes and call you for presentation.
- `Summary` of the project and explanation of what was achieved in bullet points
- `Feature achieved` Visual slide / image / diagram that accompanies the summary of the project showcasing the achieved feature
- `Architecture` section which explains the nature of the wrapping procedure. Example, for asynchronous wrapped vaults, this should outline the expected changes for the protocol in question (e.g Lido) to adopt and operate the wrapped code.
- `Pain points` section where it is described what couldn't be achieved and what was hard to do.
- `Libraries` used
- `Contact` information. This must contain a link to your twitter account which must match the account used to register in the lu.ma event to which the presentation link will be provided. The email used to register in the event will receive an invitation for the link to the online broadcast (and presentation if you are presenting online)

Any submissions past the deadline which don't contain the minimum content above will be disqualified from presenting and any top prizes (but may still earn a participation prize).

## How to submit code
Create a folder with your project name. E.g "my-fancy-wrapped-ethena-7540" within a fork of the `vault-bounties` repo. 

When you want to commit code, just open a pull request to the `vault-bounties` repo.

**We care about original submissions, therefore any repositories with single commits of the entire work at the end of the deadline will be entirely disqualified as that may be regarded as a port of an existing project (see Event Rules section)** 

**You must use proper source code history control by commiting often and showing the history of your work through the week!**

All considered valid pull requests will be merged with the `vault-bounties` post submission deadline.

## Tips to qualify to a good prize
- Have good code quality with in-line commenting of the most important steps
- Provide tests, ideally in a forked environment, that prove your mechanism works as desired. Showcasing the test passing in presentation is a good idea.
- Project feasibility/practicality in mainnet/live scenario
- Quality of the actual presentation (easiness of understanding) and your video quality (to a lesser extent)
- Be prepared for a small Q/A at the end of presentation. Questions to expect can range from motivation, inspiration and feasibility of achieving the proposed.

## After the competition
- For the top prize finalists, wallets in network X will be asked to deliver the prize
- Prizes will be delivered in X token


## Help needed
- Reach out in telegram / discord x
- If you feel unsafe or something is going wrong, please talk with us at y