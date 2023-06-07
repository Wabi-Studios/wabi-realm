////////////////////////////////////////////////////////////////////////////
//
// Copyright 2020 WabiRealm Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
////////////////////////////////////////////////////////////////////////////

#import <WabiRealm/RLMBSON.h>
#import <wabi-realm/util/optional.hpp>

namespace wabi_realm::bson {
class Bson;
template <typename> class IndexedMap;
using BsonDocument = IndexedMap<Bson>;
} // namespace wabi_realm::bson

wabi_realm::bson::Bson RLMConvertRLMBSONToBson(id<RLMBSON> b);
wabi_realm::bson::BsonDocument
RLMConvertRLMBSONArrayToBsonDocument(NSArray<id<RLMBSON>> *array);
id<RLMBSON> RLMConvertBsonToRLMBSON(const wabi_realm::bson::Bson &b);
id<RLMBSON> RLMConvertBsonDocumentToRLMBSON(
    std::optional<wabi_realm::bson::BsonDocument> b);
NSArray<id<RLMBSON>> *RLMConvertBsonDocumentToRLMBSONArray(
    std::optional<wabi_realm::bson::BsonDocument> b);