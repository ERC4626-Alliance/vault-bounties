# Tokenized Vault Competition @ ETHCC
## Resources to get Started

### Boilerplate code
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

## How to contact us

- Reach out in 4626 Alliance telegram: [@erc4626alliance](https://t.me/erc4626alliance)


## Event rules 

The event officially starts on `Thursday, the 4th of July 2024, at 8.00pm UTC +0`

You are expected to perform work on your projects and ideas until the submission deadline.

Submission deadline is `Thursday, the 11th of July 2024, at 8.00pm UTC +0`. Any submissions received or with new commited work past this point will be welcomed, but won't be eligible to present on `Friday, the 12th of July 2024`, nor to receive any top prize (but may earn a participation prize). The timestamp of submission will be taken from the last valid commit in an open pull request to the `vault-bounties`.

Projects may be built on top of existing libraries, boilerplates or reference implementations. Projects that are ported from other existing application will be disqualified.

By participating, you are acknowledging that you need to present your work in the [Tokenized Vault Competition @ ETHCC](https://lu.ma/smo8wv09?tk=orTIsj) event. This must happen either in `TheMerode` in person OR if you don't want to present live/can't be in person, a presentation video must be submitted (rules on the video recording can be read in a section below).

**Not presenting or submitting a video automatically makes you non eligible to receive any top prize.**

Presentations are expected to be small with a 3 minute time limit and should summarise the project's achievements and showcase a live go-through the codebase with some Q/A at the end. Presentations will be played live during the event day.

A live zoom link feed of the presentations day will be provided for anyone who's online who wishes to see the presentations. This will be recorded and potentially made available publicly post event.

In sum, the minimum to be able to participate and potentially get a top prize is:
- Mark yourself as attending the lu.ma event
- Submit a project as described in the below sections
- Present physically in the event day or provide a video presentation

You may participate in a team, but presentations will be single person only (a member of the team has to be chosen as the presento)


## Content of your project

Your codebase is only expected to have foundry boilerplate, any required libs, your source code and a README file.

The README MUST contain the following minimum content:
- `Unique subbmission name`. We will use this submission name to identify your project, award it with prizes and call you for presentation.
- `Summary` of the project and explanation of what was achieved in bullet points
- `Presentation` a video link (or embedded in markdown) of your presentation. Rules and guidelines in `How to make a video presentation` section below. If you are going to present in person you **DO NOT** need to provide a video link (can indicate 'In person' in this field)
- `Feature achieved` Visual slide / image / diagram that accompanies the summary of the project showcasing the achieved feature
- `Architecture` section which explains the nature of the wrapping procedure. Example, for asynchronous wrapped vaults, this should outline the expected changes for the protocol in question (e.g Lido) to adopt and operate the wrapped code.
- `Pain points` section where it is described what couldn't be achieved and what was hard to do.
- `Libraries` used
- `EVM address for prize submission`. An address at your descretion must be provided to receive prizes.
- `Contact` information, which must contain your **twitter handle which you used to register to the lu.ma event**. This is important so we can link submissions in this repository to actual presenters in the in-person meeting. 

Any submissions past the deadline which don't contain the minimum content above will be disqualified from presenting and from receiving any top prizes (but may still earn a participation prize).

## How to submit code
Create a folder with your project name. E.g "my-fancy-wrapped-ethena-7540" within a fork of the `vault-bounties` repo. 

When you want to commit code, just open a pull request to the `vault-bounties` repo.

**We care about original submissions, therefore any repositories with single commits of the entire work at the end of the deadline will be entirely disqualified as that may be regarded as a port of an existing project (see Event Rules section)** 

**You must use proper source control by commiting often and showing the history of your work through the week!**

All considered valid pull requests will be merged with the `vault-bounties` post submission deadline.

## How to make a video presentation

Any contestant who doesn't want to present live or can't make it to the event in person can present by recording a video presentation.

This presentation has the following requirements:
- Video publicly available (embedded in the markdown/available on youtube are good ideas)
- Minimum of 1 minute and a maximum of 3 minutes per presentation!
- Must share your whole screen
- Should have your voice walking us through the presentation (i.e it must not be a silent presentation)
- Minimum 720p resolution, but ideally 1080p+

To do a presentation in a good quality, you recommend to use Loom, Zoom screenshare or QuickTime player if you use your Mac

Please keep introductions in your video brief and make sure your environment is ready (tabs, windows, content you are going to present) before starting to record.


## Tips to qualify to a good prize

- Have good code quality with in-line commenting of the most important steps
- Provide tests, ideally in a forked environment, that prove your mechanism works as desired. Showcasing the test passing in presentation with logs is a good idea.
- Project feasibility/practicality in mainnet/live scenario
- Quality of the actual presentation (easiness of understanding) and your video quality (to a lesser extent)
- Be prepared for a small Q/A at the end of presentation. Questions to expect can range from motivation, inspiration and feasibility of achieving the proposed.

## After the competition

- Prizes will be delivered in USDC tokens within approximately one week by the 4626 Alliance 


