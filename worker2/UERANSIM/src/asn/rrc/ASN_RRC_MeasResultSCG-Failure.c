/*
 * Generated by asn1c-0.9.29 (http://lionet.info/asn1c)
 * From ASN.1 module "NR-RRC-Definitions"
 * 	found in "asn/nr-rrc-15.6.0.asn1"
 * 	`asn1c -fcompound-names -pdu=all -findirect-choice -fno-include-deps -gen-PER -no-gen-OER -no-gen-example -D rrc`
 */

#include "ASN_RRC_MeasResultSCG-Failure.h"

static asn_TYPE_member_t asn_MBR_ASN_RRC_MeasResultSCG_Failure_1[] = {
	{ ATF_NOFLAGS, 0, offsetof(struct ASN_RRC_MeasResultSCG_Failure, measResultPerMOList),
		(ASN_TAG_CLASS_CONTEXT | (0 << 2)),
		-1,	/* IMPLICIT tag at current level */
		&asn_DEF_ASN_RRC_MeasResultList2NR,
		0,
		{ 0, 0, 0 },
		0, 0, /* No default value */
		"measResultPerMOList"
		},
};
static const ber_tlv_tag_t asn_DEF_ASN_RRC_MeasResultSCG_Failure_tags_1[] = {
	(ASN_TAG_CLASS_UNIVERSAL | (16 << 2))
};
static const asn_TYPE_tag2member_t asn_MAP_ASN_RRC_MeasResultSCG_Failure_tag2el_1[] = {
    { (ASN_TAG_CLASS_CONTEXT | (0 << 2)), 0, 0, 0 } /* measResultPerMOList */
};
static asn_SEQUENCE_specifics_t asn_SPC_ASN_RRC_MeasResultSCG_Failure_specs_1 = {
	sizeof(struct ASN_RRC_MeasResultSCG_Failure),
	offsetof(struct ASN_RRC_MeasResultSCG_Failure, _asn_ctx),
	asn_MAP_ASN_RRC_MeasResultSCG_Failure_tag2el_1,
	1,	/* Count of tags in the map */
	0, 0, 0,	/* Optional elements (not needed) */
	1,	/* First extension addition */
};
asn_TYPE_descriptor_t asn_DEF_ASN_RRC_MeasResultSCG_Failure = {
	"MeasResultSCG-Failure",
	"MeasResultSCG-Failure",
	&asn_OP_SEQUENCE,
	asn_DEF_ASN_RRC_MeasResultSCG_Failure_tags_1,
	sizeof(asn_DEF_ASN_RRC_MeasResultSCG_Failure_tags_1)
		/sizeof(asn_DEF_ASN_RRC_MeasResultSCG_Failure_tags_1[0]), /* 1 */
	asn_DEF_ASN_RRC_MeasResultSCG_Failure_tags_1,	/* Same as above */
	sizeof(asn_DEF_ASN_RRC_MeasResultSCG_Failure_tags_1)
		/sizeof(asn_DEF_ASN_RRC_MeasResultSCG_Failure_tags_1[0]), /* 1 */
	{ 0, 0, SEQUENCE_constraint },
	asn_MBR_ASN_RRC_MeasResultSCG_Failure_1,
	1,	/* Elements count */
	&asn_SPC_ASN_RRC_MeasResultSCG_Failure_specs_1	/* Additional specs */
};

