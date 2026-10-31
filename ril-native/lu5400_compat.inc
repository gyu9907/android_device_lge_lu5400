/* LU540141 libril.so SHA256 add230345c2400a52d1feef31b5c2276957c60a929ff9cadbede48dc7de97133.
 * Private dispatch layouts: 0x5b44, 0x5a90, 0x59e0, 0x591c.
 * Preserve stock allocation lifetime on successful heap-backed requests;
 * ownership after the callback is not established.
 * Ordinary CM11 requests continue using the standard handlers.
 */
struct LgeStringInt { char *text; int value; };
struct LgeIntString { int value; char *text; };
struct LgeIntStrings { int value; char *text[3]; };

static void dispatchLgeDtmfStart(Parcel &p, RequestInfo *ri) {
    // The stock modem's requestDtmfStart omits its optional AT argument
    // for a negative value. CM11 supplies only the key, so select that path.
    LgeStringInt arg = { strdupReadString(p), -1 };
    if (arg.text == NULL || (p.dataAvail() != 0 && p.readInt32(&arg.value) != NO_ERROR)) {
        free(arg.text); invalidCommandBlock(ri); return;
    }
    s_callbacks.onRequest(ri->pCI->requestNumber, &arg, sizeof(arg), ri);
    free(arg.text);
}
static void dispatchLgeStringInt(Parcel &p, RequestInfo *ri) {
    LgeStringInt *arg = (LgeStringInt *)calloc(1, sizeof(*arg));
    if (!arg) { invalidCommandBlock(ri); return; }
    arg->text = strdupReadString(p);
    if (arg->text == NULL || p.readInt32(&arg->value) != NO_ERROR) {
        free(arg->text); free(arg); invalidCommandBlock(ri); return;
    }
    s_callbacks.onRequest(ri->pCI->requestNumber, arg, sizeof(*arg), ri);
    // Stock releases the string here but not the outer allocation.
    free(arg->text);
}
static void dispatchLgeIntString(Parcel &p, RequestInfo *ri) {
    LgeIntString arg = {-1, NULL};
    if (p.readInt32(&arg.value) != NO_ERROR) {
        invalidCommandBlock(ri); return;
    }
    arg.text = strdupReadString(p);
    s_callbacks.onRequest(ri->pCI->requestNumber, &arg, sizeof(arg), ri);
    free(arg.text);
}
static void dispatchLgeOwnedIntString(Parcel &p, RequestInfo *ri) {
    LgeIntString *arg = (LgeIntString *)calloc(1, sizeof(*arg));
    if (!arg) { invalidCommandBlock(ri); return; }
    if (p.readInt32(&arg->value) != NO_ERROR) {
        free(arg); invalidCommandBlock(ri); return;
    }
    arg->text = strdupReadString(p);
    s_callbacks.onRequest(ri->pCI->requestNumber, arg, sizeof(*arg), ri);
}
static void dispatchLgeOwnedStrings(Parcel &p, RequestInfo *ri) {
    LgeIntStrings *arg = (LgeIntStrings *)calloc(1, sizeof(*arg));
    if (!arg) { invalidCommandBlock(ri); return; }
    if (p.readInt32(&arg->value) != NO_ERROR) {
        free(arg); invalidCommandBlock(ri); return;
    }
    for (int i = 0; i < 3; ++i) arg->text[i] = strdupReadString(p);
    s_callbacks.onRequest(ri->pCI->requestNumber, arg, sizeof(*arg), ri);
}
static int responseLgeIntString(Parcel &p, void *response, size_t length) {
    if (!response || length != sizeof(LgeIntString)) return RIL_ERRNO_INVALID_RESPONSE;
    LgeIntString *arg = (LgeIntString *)response;
    p.writeInt32(arg->value);
    writeStringToParcel(p, arg->text);
    return 0;
}
static int responseLgeThreeStrings(Parcel &p, void *response, size_t length) {
    struct Payload {char *text[3]; int first, second;};
    if (!response || length != sizeof(Payload)) return RIL_ERRNO_INVALID_RESPONSE;
    Payload *arg = (Payload *)response;
    p.writeInt32(arg->first); p.writeInt32(arg->second);
    for (int i = 0; i < 3; ++i) writeStringToParcel(p, arg->text[i]);
    return 0;
}

// CM11 sends decimal strings; LU540141 expects the two integer values.
static void dispatchLgeDeactivate(Parcel &p, RequestInfo *ri) {
    int32_t count;
    int values[2];
    if (p.readInt32(&count) != NO_ERROR || count != 2) {
        invalidCommandBlock(ri); return;
    }
    for (int i = 0; i < 2; ++i) {
        char *value = strdupReadString(p);
        char *end = NULL;
        errno = 0;
        long parsed = value ? strtol(value, &end, 10) : -1;
        bool valid = errno != ERANGE && value && end != value && *end == 0 && parsed >= 0 && parsed <= 0x7fffffffL;
        free(value);
        if (!valid) { invalidCommandBlock(ri); return; }
        values[i] = (int)parsed;
    }
    s_callbacks.onRequest(ri->pCI->requestNumber, values, sizeof(values), ri);
}
