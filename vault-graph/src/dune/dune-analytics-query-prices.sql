-- Prices https://dune.com/queries/3904744
WITH
  latest_prices AS (
    SELECT
      contract_address,
      price,
      ROW_NUMBER() OVER (
        PARTITION BY
          contract_address
        ORDER BY
          minute DESC
      ) as row_num
    FROM
      prices.usd
    WHERE
      blockchain = 'ethereum'
      AND minute >= NOW() - INTERVAL '1' DAY
      AND contract_address IN (
        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2,
        0x4c9EDD5852cd905f086C759E8383e09bff1E68B3,
        0xb6D149C8DdA37aAAa2F8AD0934f2e5682C35890B,
        0xD9A442856C234a39a81a089C06451EBAa4306a72,
        0x6B175474E89094C44Da98b954EedeAC495271d0F,
        0xf951E335afb289353dc249e82926178EaC7DEd78,
        0xFAe103DC9cf190eD75350761e95403b7b8aFa6c0,
        0xCd5fE23C85820F7B72D0926FC9b05b43E359b7ee,
        0x5E8422345238F34275888049021821E8E08CAa1f,
        0xdBB7a34Bf10169d6d2D0d02A6cbb436cF4381BFa,
        0xbf5495Efe5DB9ce00f80364C8B423567e58d2110,
        0xA1290d69c65A6Fe4DF752f95823fae25cB99e5A7,
        0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48,
        0x4d224452801ACEd8B2F0aebE155379bb5D594381,
        0x9D39A5DE30e57443BfF2A8307A4256c8797A3497,
        0xf939E0A03FB07F59A73314E73794Be0E57ac1b4E,
        0xa5f2211B9b8170F694421f2046281775E8468044,
        0x853d955aCEf822Db058eb8505911ED77F175b99e,
        0xc28eb2250d1AE32c7E74CFb6d6b86afC9BEb6509,
        0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0,
        0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84,
        0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B,
        0x04C154b66CB340F3Ae24111CC767e0184Ed00Cc6,
        0xd5F7838F5C461fefF7FE49ea5ebaF7728bB0ADfa,
        0x42496acd2c7b52CE90Ed65adA6CafB0e893e2474,
        0xA35b1B31Ce002FBF2058D22F30f95D405200A15b,
        0x616e8BfA43F920657B3497DBf40D6b1A02D4608d,
        0x10978Db3885bA79Bf1Bc823E108085FB88e6F02f,
        0xc69Ad9baB1dEE23F4605a82b3354F8E40d1E5966,
        0xe24BA27551aBE96Ca401D39761cA2319Ea14e3CB,
        0x72B886d09C117654aB7dA13A14d603001dE0B777,
        0x43Dfc4159D86F3A37A5A4B3D4580b888ad7d4DDd,
        0x1BED97CBC3c24A4fb5C069C6E311a967386131f7,
        0x40D16FC0246aD3160Ccc09B8D0D3A2cD28aE6C2f,
        0xBe53A109B494E5c9f97b9Cd39Fe969BE68BF6204,
        0x3231Cb76718CDeF2155FC47b5286d82e6eDA273f,
        0x856c4Efb76C1D1AE02e20CEB03A2A6a08b0b8dC3,
        0x577A7f7EE659Aa14Dc16FD384B3F8078E23F1920,
        0xB05cABCd99cf9a73b19805edefC5f67CA5d1895E,
        0x028eC7330ff87667b6dfb0D94b954c820195336c,
        0xe3668873D944E4A949DA05fc8bDE419eFF543882,
        0xae78736Cd615f374D3085123A210448E74Fc6393,
        0xa8258deE2a677874a48F5320670A869D74f0cbC1,
        0x6E9455D109202b426169F0d8f01A3332DAE160f3,
        0x59D9356E565Ab3A36dD77763Fc0d87fEaf85508C,
        0x58900d761Ae3765B75DDFc235c1536B527F25d8F,
        0x4591DBfF62656E7859Afe5e45f6f47D3669fBB28,
        0x05ff47AFADa98a98982113758878F9A8B9FddA0a,
        0xa2E3356610840701BDf5611a53974510Ae27E2e1,
        0x1E19CF2D73a72Ef1332C882F20534B6519Be0276,
        0x63E0d47A6964aD1565345Da9bfA66659F4983F02,
        0xf43211935C781D5ca1a41d2041F397B8A7366C7A,
        0xe4e72f872c4048925a78E1e6Fddac411C9ae348A,
        0x7bAf258049cc8B9A78097723dc19a8b103D4098F,
        0xD60EeA80C83779a8A5BFCDAc1F3323548e6BB62d,
        0xE46a5E19B19711332e33F33c2DB3eA143e86Bc10,
        0x93d199263632a4EF4Bb438F1feB99e57b4b5f0BD,
        0x6B268960693359F8c64E043D72ce7580867521B2,
        0x6568921f9059B6b8a3902651783A7A0E74Ca83fF,
        0x1c085195437738d73d75DC64bC5A3E098b7f93b1,
        0xCfCA23cA9CA720B6E98E3Eb9B6aa0fFC4a5C08B9,
        0x5D5bc446C70b07FA7fE53b3AFD58081831A0712A
      )
  )
SELECT
  contract_address,
  price
FROM
  latest_prices
WHERE
  row_num = 1;
