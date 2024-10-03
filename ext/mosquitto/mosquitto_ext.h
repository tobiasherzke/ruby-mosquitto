#ifndef MOSQUITTO_EXT_H
#define MOSQUITTO_EXT_H

#include <mosquitto.h>
#include <pthread.h>
#include <ruby.h>
#include <ruby/thread.h>
#include <ruby/encoding.h>
#include <ruby/io.h>

extern rb_encoding *binary_encoding;
extern VALUE rb_mMosquitto;
extern VALUE rb_eMosquittoError;
extern VALUE rb_cMosquittoClient;
extern VALUE rb_cMosquittoMessage;
extern VALUE intern_call;

#define MosquittoEncode(str) rb_enc_associate(str, binary_encoding)
#define MosquittoError(desc) rb_raise(rb_eMosquittoError, "%s", desc);

#include "client.h"
#include "message.h"

#endif
