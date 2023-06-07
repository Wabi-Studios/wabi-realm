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

#import "RLMBSON_Private.hpp"
#import "RLMCollection.h"
#import "RLMFindOneAndModifyOptions_Private.hpp"

@interface RLMFindOneAndModifyOptions () {
  wabi_realm::app::MongoCollection::FindOneAndModifyOptions _options;
};
@end

@implementation RLMFindOneAndModifyOptions

- (instancetype)initWithProjection:(id<RLMBSON> _Nullable)projection
                              sort:(id<RLMBSON> _Nullable)sort
                            upsert:(BOOL)upsert
           shouldReturnNewDocument:(BOOL)shouldReturnNewDocument {
  if (self = [super init]) {
    self.upsert = upsert;
    self.shouldReturnNewDocument = shouldReturnNewDocument;
    self.projection = projection;
    self.sort = sort;
  }
  return self;
}

- (instancetype)initWithProjection:(id<RLMBSON> _Nullable)projection
                           sorting:(NSArray<id<RLMBSON>> *)sorting
                            upsert:(BOOL)upsert
           shouldReturnNewDocument:(BOOL)shouldReturnNewDocument {
  if (self = [super init]) {
    self.upsert = upsert;
    self.shouldReturnNewDocument = shouldReturnNewDocument;
    self.projection = projection;
    self.sorting = sorting;
  }
  return self;
}

- (wabi_realm::app::MongoCollection::FindOneAndModifyOptions)
    _findOneAndModifyOptions {
  return _options;
}

- (id<RLMBSON>)projection {
  return RLMConvertBsonDocumentToRLMBSON(_options.projection_bson);
}

- (id<RLMBSON>)sort {
  return RLMConvertBsonDocumentToRLMBSON(_options.sort_bson);
}

- (NSArray<id<RLMBSON>> *)sorting {
  return RLMConvertBsonDocumentToRLMBSONArray(_options.sort_bson);
}

- (BOOL)upsert {
  return _options.upsert;
}

- (BOOL)shouldReturnNewDocument {
  return _options.return_new_document;
}

- (void)setProjection:(id<RLMBSON>)projection {
  if (projection) {
    auto bson =
        wabi_realm::bson::BsonDocument(RLMConvertRLMBSONToBson(projection));
    _options.projection_bson =
        std::optional<wabi_realm::bson::BsonDocument>(bson);
  } else {
    _options.projection_bson = wabi_realm::util::none;
  }
}

- (void)setSort:(id<RLMBSON>)sort {
  if (sort) {
    auto bson = wabi_realm::bson::BsonDocument(RLMConvertRLMBSONToBson(sort));
    _options.sort_bson = std::optional<wabi_realm::bson::BsonDocument>(bson);
  } else {
    _options.sort_bson = wabi_realm::util::none;
  }
}

- (void)setSorting:(NSArray<id<RLMBSON>> *)sorting {
  _options.sort_bson = RLMConvertRLMBSONArrayToBsonDocument(sorting);
}

- (void)setUpsert:(BOOL)upsert {
  _options.upsert = upsert;
}

- (void)setShouldReturnNewDocument:(BOOL)returnNewDocument {
  _options.return_new_document = returnNewDocument;
}

@end
