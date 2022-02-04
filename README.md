# Carrot v1 contracts

This repo contains the smart contracts for Carrot v1, a platform that enables
easy, hassle-free and efficient incentivization, rewarding what really matters
in a capital efficient way.

Incentivization is enabled by flexible KPI tokens, collateralized smart
contracts running on any EVM-compatible chain. The collateral is tied to a
series of conditions, and unlocked depending on how those conditions resolve
(the real-world results of the conditions are reported back on-chain by
different kind of oracles). The collateral can either become redeemable by KPI
token holders if the KPI token creator's goal is reached, or sent back to the
creator if it's not, achieving capital efficient incentivization in the process.

A Carrot campaign typically consists in a party defining a goal (i.e. will this
pool on Swapr have more than x USD liquidity by date y, will the USD price of x
be y or more USD by date z, etc etc) represented by one or more conditions and
creating a collateralized KPI token for it.

The KPI token(s) (which can take on any form or any unlocking logic
implementable on the EVM, more info on this later) can then be distributed to
the parties the efforts of which can realistically have the most impact on
reaching the goal. The parties then know that if the goal is reached, they'll
receive a reward for their service, while if the goal is not reached, the KPI
tokens will expire and they'll get either nothing or a smaller amount of
rewards, with the KPI token creator getting back all or most of the collateral.

In short, this is what Carrot v1 is about.

## KPI token and oracle templates and managers

Carrot v1 is designed with flexibility in mind. The maximum amount of
flexibility is achieved by allowing third parties to create their own KPI token
and oracle templates. Any party can code the functionality they want in Carrot
v1 and use it as a result, putting almost no limits on incentivization
creativity.

This is mainly achieved using 2 contracts: `KPITokensManager` and
`OraclesManager`. These contracts act as a registry for both KPI token and
oracle templates, and at the same time can instantiate specific templates (using
ERC-1167 clones to maximize gas efficiency).

Each of these managers support template addition, removal, upgrade, update and
instantiation, as well as some readonly functions to query templates' state.

Most of these actions are protected and can only be performed by specific
entities in the platform. In particular, addition, removal, upgrade and update
can only be performed by the manager contract's owner (either DXdao or a
custom-made guild), while template instantiation can only be performed by the
`KPITokensFactory`.

The managers come out of the box with a small amount of powerful templates, with
the goal of letting the community come up with additional use cases that can
also lead to custom-made products based off of the Carrot v1's platform.

In particular, a multiple ERC20 collateral, multi-condition,
minimum-payout-enabled ERC20 KPI token has been developed and will be the first
KPI token template available. This token template lets anyone create ERC20
tokens that can easily be distributed via farming or airdrops, and that can be
backed by multiple ERC20 collaterals. Multiple conditions (oracles) can be
specified for a single KPI token, as well as the relationship in which they're
in and resolve (either AND or weighted). A minimum payout can also be specified,
given out regardless of whether anyone of the goals is actually reached. The
logical relationship between conditions is an interesting concept. If a KPI
token is created with 2 conditions A, B tied together with and AND relationship,
if one of the 2 conditions fails, the whole KPI token is considered to be
worthless (i.e. any collaterals will be sent back to the token creators). Using
a weighted relationship instead, conditions can be weighted, and collateral can
be given out specifically based on what condition was reached and what not. With
the same A, B example used before, if condition A has a weight of 2 and B of 1,
if A is reached, 2/3rds of the collaterals will be redeemable by token holders.
If condition B also verifies, the remaining third of the collaterals will be
redeemable by the KPI token holders too, but if it fails, it gets sent back to
the KPI token creator. Redeeming the collateral will burn any held ERC20 KPI
token.

As for oracle templates, a Reality.eth oracle will initially be available.
Reality.eth is a crowdsourced oracle, battle-tested by DXdao through Omen and
its prediction markets.

The idea, for oracles at least, is that to minimize trust and human intervention
by allowing automatable oracles in a near future. DXdao is developing its own
cryptoincentivized smart contract execution network, and when available, Carrot
v1 will be a first party integration. Having a decentralized network of
bots/humans executing functions in exchange for a reward will drastically
improve the decentralization and user experience, all the while opening up new
opportunities for creative oracles implementation (for example automatic token
price/TVL oracles or any oracle fetching onchain data).

## KPITokensFactory

The KPI tokens factory is ideally the contract with which KPI token creators
will interact the most. Its most important function is the `createToken`, which
takes in 4 parameters, `_id`, `_description`, `_initializationData` and
`_oraclesInitializationData`. The factory is simply in charge of initializing
the KPI token, the oracles eventually connected to it, and collecting the
protocol fee. The logic for these functions are defined by the KPI token
template, and are fully extensible to allow for custom behavior.

Explanation of the input parameters follows:

- `_id`: an `uint` telling the factory which KPI token template must be used.
- `_description`: a `string` describing what the KPI token is about (the goals,
  how they can be reached, and eventually info about how to answer any attached
  oracles, if the oracles are crowdsourced). In order to save on gas fees, it is
  _highly_ advisable to upload a text file to IPFS and pass in a CID.
- `_initializationData`: ABI-encoded KPI token initialization data specific to
  the instantiated template. To know what data to use and how to encode it, have
  a look at the code for the template you want to use, in particular to the
  `initialize` function.
- `_oraclesInitializationData`: ABI-encoded oracles data specific to the
  instantiated template. This data is used by the template to instantiate any
  oracles needed to report goals' data back on-chain. To know what data to use
  and how to encode it, have a look at the code for the template you want to
  use, in particular to the `initializeOracles` function.

## Implementing a KPI token template

A KPI token template can be defined by simply implementing the `IKPIToken`
interface. The functions that must be overridden are:

- `initialize`: this function is called by the factory while initializing the
  KPI token and contains all the initialization logic (collaterals transfer, and
  state setup, as well as the KPI token minting and transfer to any wanted
  party). 4 input parameters are passed in by the factory: `_creator`, which is
  the address of the account creating the KPI token, `_template` which is a
  struct containing a snapshot of the used template spec at creation-time,
  `_description`, which is a string the contents of which describe what the KPI
  token is about, and `_data`, which contains any parameters/configuration
  required by the initialization function in an ABI-encoded fashion.
- `initializeOracles`: oracle(s) initialization is performed in this function.
  The `_oraclesManager` contract address is passed in as an input alongside
  `_data`, the arbitrary ABI-encoded data needed to instantiate the oracles.
- `collectProtocolFees`: protocol fees collection is implemented in this
  function. The logic surrounding protocol fee collection is heavily
  implementation-dependent and should be discussed with DXdao/Carrot guild
  before a proposal to add the template is submitted. Additionally, the idea
  will eventually be to let KPI token template developers keep part of the fee
  as a thank you for their much, much appreciated service to the community.
- `finalize`: finalization logic is implemented here. This function should only
  be callable by the oracles associated with the token. Once all the oracles
  have reported their final results, logic to properly allocate the collaterals
  (either to the KPI token holders or the KPI token creator) must be implemented
  accordingly. Any non-redeemable collateral should at this point be sent back
  to the KPI token creator
- `redeem`: this is the function KPI token holders call to redeem the collateral
  they have earned (if any was unlocked by `finalize`). This function should
  ideally (but not necessarily) burn the user-held KPI token(s) in exchange for
  the collateral.
- `finalized`: a view function that helps understanding if the KPI token is in a
  finalized state or not.
- `protocolFee`: a view function to get a fee breakdown for the KPI token
  creation.

In general, a good place to have a look at to get started with KPI token
development is the `ERC20KPIToken` (talk is cheap, show me the code).
