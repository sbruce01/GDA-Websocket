const { ApolloServer, gql } = require('apollo-server');
const fetch = (...args) =>
  import('node-fetch').then(({ default: fetch }) => fetch(...args));

const baseURL = `http://localhost:5005`

function getFilters(info) {
    user_functions = info.operation.selectionSet.selections
        for (let i = 0; i < user_functions.length; i++){
            if (user_functions[i].name.value===info.fieldName) {
                for (let j = 0; j < user_functions[i].selectionSet.selections.length; j++){
                    console.log(user_functions[i].selectionSet.selections[j].name.value)
                }                
            }
        }
  }

const typeDefs = gql`
    type Query {
        data: [Trade!]!
        dataWithStartTime(startTime: String!): [Trade!]!
        dataWithMultiple(startTime: String!, exchange: [String!]): [Trade!]!
        logHeader:[Trade!]!
        allInfo:[Trade!]!
    }

    type Trade {
        date: String!
        time: String!
        sym: String!
        orderID: String!
        price: Float!
        tradeID: String!
        side: String!
        size: Float!
        exchange: String!
    }
`;

const resolvers = {
    Query: {
      data: () => {
        return fetch(`${baseURL}/getData`).then(res => res.json())
      },
      dataWithStartTime: (parent, args) => {
        const { startTime } = args
        return fetch(`${baseURL}/getData?sd=${startTime}`).then(res => res.json())
      },
      dataWithMultiple: (parent, args) => {
        const { startTime, exchange } = args
        return fetch(`${baseURL}/getData?exc=${exchange}&sd=${startTime}`).then(res => res.json())
      },
      allInfo: (_, args, context, info) => {
        getFilters(info)
        return [{tradeId: "yes"}]
    }
    },
  }

const server = new ApolloServer({ typeDefs, resolvers });

// The `listen` method launches a web server.
server.listen().then(({ url }) => {
  console.log(`🚀  Server ready at ${url}`);
});