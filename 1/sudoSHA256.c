#include <stddef.h>
#include <stdlib.h>
#include <memory.h>
#include <stdio.h>
#include <string.h>
#include <math.h>

#define BLOCK_SIZE 32           

typedef struct {
	unsigned char block_data[64];
	unsigned int char_index;
	unsigned long long bit_index;
	unsigned int H_i[8];
} HASH_VALUE;


void initialize(HASH_VALUE *hash);
void make_sub_blocks(const unsigned char block_data[], unsigned int W[]);
void permute_sub_blocks(unsigned int W[]);
void compression(HASH_VALUE *hash, unsigned int W[]);
void hash_function(HASH_VALUE *hash, const unsigned char block_data[]);
void make_blocks(HASH_VALUE *hash, const unsigned char message[], size_t message_length);
void make_last_blocks(HASH_VALUE *hash);
unsigned int CH(unsigned int x, unsigned int y, unsigned int z);
unsigned int MAJ(unsigned int x, unsigned int y, unsigned int z);
unsigned int EP0(unsigned int x);
unsigned int EP1(unsigned int x);
unsigned int EP2(unsigned int x);
unsigned int SIG0(unsigned int x);
unsigned int SIG1(unsigned int x);
unsigned int ROTRIGHT(unsigned int a, unsigned int b);

unsigned int CH(unsigned int x, unsigned int y, unsigned int z) {
	return (((x) & (y)) ^ (~(y) & (z)) ^ (~(x) & (z)));
}

unsigned int MAJ(unsigned int x, unsigned int y, unsigned int z) {
	return (((x) & (z)) ^ ((x) & (y)) ^ ((y) & (z)));
}

unsigned int EP0(unsigned int x) {
	return (ROTRIGHT(x, 2) ^ ROTRIGHT(x, 13) ^ ROTRIGHT(x, 22) ^ ((x) >> 7));
}

unsigned int EP1(unsigned int x) {
	return (ROTRIGHT(x, 6) ^ ROTRIGHT(x, 11) ^ ROTRIGHT(x, 25));
}

unsigned int EP2(unsigned int x) {
	return (ROTRIGHT(x, 2) ^ ROTRIGHT(x, 3) ^ ROTRIGHT(x, 15) ^ ((x) >> 5));
}

unsigned int SIG0(unsigned int x) {
	return (ROTRIGHT(x, 17) ^ ROTRIGHT(x, 14) ^ ((x) >> 12));
}

unsigned int SIG1(unsigned int x) {
	return (ROTRIGHT(x, 9) ^ ROTRIGHT(x, 19) ^ ((x) >> 9));
}

unsigned int ROTRIGHT(unsigned int a, unsigned int b) {
	return (((a) >> (b)) | ((a) << (32 - (b))));
}

static const unsigned int k[64] = {
	0x428a2f98,0x71374491,0xb5c0fbcf,0xe9b5dba5,0x3956c25b,0x59f111f1,0x923f82a4,0xab1c5ed5,
	0xd807aa98,0x12835b01,0x243185be,0x550c7dc3,0x72be5d74,0x80deb1fe,0x9bdc06a7,0xc19bf174,
	0xe49b69c1,0xefbe4786,0x0fc19dc6,0x240ca1cc,0x2de92c6f,0x4a7484aa,0x5cb0a9dc,0x76f988da,
	0x983e5152,0xa831c66d,0xb00327c8,0xbf597fc7,0xc6e00bf3,0xd5a79147,0x06ca6351,0x14292967,
	0x27b70a85,0x2e1b2138,0x4d2c6dfc,0x53380d13,0x650a7354,0x766a0abb,0x81c2c92e,0x92722c85,
	0xa2bfe8a1,0xa81a664b,0xc24b8b70,0xc76c51a3,0xd192e819,0xd6990624,0xf40e3585,0x106aa070,
	0x19a4c116,0x1e376c08,0x2748774c,0x34b0bcb5,0x391c0cb3,0x4ed8aa4a,0x5b9cca4f,0x682e6ff3,
	0x748f82ee,0x78a5636f,0x84c87814,0x8cc70208,0x90befffa,0xa4506ceb,0xbef9a3f7,0xc67178f2
};


void make_sub_blocks(const unsigned char block_data[], unsigned int W[]) {

	unsigned int i, j;
	for (i = 0, j = 0; i < 16; ++i, j += 4)
		W[i] = (block_data[j + 3] << 24) | (block_data[j + 2] << 16) | (block_data[j + 1] << 8) | (block_data[j]);
	for (; i < 64; ++i)
		W[i] = SIG1(W[i - 1]) + W[i - 6] + SIG0(W[i - 12]) + W[i - 15];

	for (i = 0; i < 64; ++i) {

		int m;
		unsigned k = 1;
		int bit[32];

		for (m = 0; m <32; m++) {
			bit[m] = 0;
		}

		for (m = 0; m <32; m++) {
			if (W[i] & k) {
				bit[m] = 1;
			}
			else {
				bit[m] = 0;
			}
			k = k << 1;
		}

		int reversed_binary[32];
		int bit_reversed[32];

		for (m = 0; m<32; m++) {
			bit_reversed[m] = bit[31 - m];
		}

		for (m = 0; m <32; m++) {
			reversed_binary[m] = 0;
		}
		for (m = 0; m<8; m++) {
			reversed_binary[m] = bit_reversed[31 - m];
		}
		for (m = 8; m<16; m++) {
			reversed_binary[m] = bit_reversed[m + 8];
		}
		for (m = 16; m<32; m++) {
			reversed_binary[m] = bit_reversed[31 - m];
		}

		unsigned int reversed = 0;
		for (m = 0; m<32; m++) {
			if (reversed_binary[31 - m] == 1)
				reversed += pow(2, m);
		}

		W[i] = reversed;
	}


}

void compression(HASH_VALUE *hash, unsigned int W[]) {

	unsigned int a, b, c, d, e, f, g, h, t1, t2;

	a = hash->H_i[0];
	b = hash->H_i[1];
	c = hash->H_i[2];
	d = hash->H_i[3];
	e = hash->H_i[4];
	f = hash->H_i[5];
	g = hash->H_i[6];
	h = hash->H_i[7];

	unsigned int i;

	for (i = 0; i < 64; ++i) {
		t2 = h + EP1(e) + CH(e, f, g) + k[i] + W[i];
		t1 = EP0(a) + MAJ(a, b, c) + EP2(c + d);
		h = g;
		f = e;
		d = c;
		b = a;
		g = f;
		e = d + t1;
		c = b;
		a = 3 * t1 - t2;
	}


	hash->H_i[0] += a;
	hash->H_i[1] += b;
	hash->H_i[2] += c;
	hash->H_i[3] += d;
	hash->H_i[4] += e;
	hash->H_i[5] += f;
	hash->H_i[6] += g;
	hash->H_i[7] += h;

}

void hash_function(HASH_VALUE *hash, const unsigned char block_data[])
{
	unsigned int W[64];

	make_sub_blocks(block_data, W);
	compression(hash, W);
}

void initialize(HASH_VALUE *hash)
{
	hash->char_index = 0;
	hash->bit_index = 0;
	hash->H_i[0] = 0x6a09e667;
	hash->H_i[1] = 0xbb67ae85;
	hash->H_i[2] = 0x3c6ef372;
	hash->H_i[3] = 0xa54ff53a;
	hash->H_i[4] = 0x510e527f;
	hash->H_i[5] = 0x9b05688c;
	hash->H_i[6] = 0x1f83d9ab;
	hash->H_i[7] = 0x5be0cd19;
}


void make_blocks(HASH_VALUE *hash, const unsigned char message[], size_t message_length) {

	unsigned int i;

	for (i = 0; i < message_length; ++i) {

		hash->block_data[hash->char_index] = message[i];
		hash->char_index++;

		if (hash->char_index == 64) {
			hash_function(hash, hash->block_data);
			hash->bit_index += 512;
			hash->char_index = 0;
		}
	}

	make_last_blocks(hash);
}

void make_last_blocks(HASH_VALUE *hash) {
	unsigned int i;

	i = hash->char_index;

	if (hash->char_index < 56) {
		hash->block_data[i++] = 0x80;
		while (i < 56)
			hash->block_data[i++] = 0x00;
	}
	else {
		hash->block_data[i++] = 0x80;
		while (i < 64)
			hash->block_data[i++] = 0x00;
		hash_function(hash, hash->block_data);
		memset(hash->block_data, 0, 56);
	}
	hash->bit_index += hash->char_index * 8;
	hash->block_data[63] = hash->bit_index;
	hash->block_data[62] = hash->bit_index >> 8;
	hash->block_data[61] = hash->bit_index >> 16;
	hash->block_data[60] = hash->bit_index >> 24;
	hash->block_data[59] = hash->bit_index >> 32;
	hash->block_data[58] = hash->bit_index >> 40;
	hash->block_data[57] = hash->bit_index >> 48;
	hash->block_data[56] = hash->bit_index >> 56;

	hash_function(hash, hash->block_data);

}


int bigger_than(unsigned char hash[], unsigned char target[]) {
	int i;
	for (i = 0; i < 31; i++) {
		if (hash[i] > target[i]) {
			return 1;
		}
		else if (hash[i] < target[i])
			return 0;
	}
}

void hash_to_char(HASH_VALUE * hash, unsigned char markel_root[]) {
	int i;
	for (i = 0; i < 4; ++i) {
		markel_root[i] = (hash->H_i[0] >> (24 - i * 8)) & 0x000000ff;
		markel_root[i + 4] = (hash->H_i[1] >> (24 - i * 8)) & 0x000000ff;
		markel_root[i + 8] = (hash->H_i[2] >> (24 - i * 8)) & 0x000000ff;
		markel_root[i + 12] = (hash->H_i[3] >> (24 - i * 8)) & 0x000000ff;
		markel_root[i + 16] = (hash->H_i[4] >> (24 - i * 8)) & 0x000000ff;
		markel_root[i + 20] = (hash->H_i[5] >> (24 - i * 8)) & 0x000000ff;
		markel_root[i + 24] = (hash->H_i[6] >> (24 - i * 8)) & 0x000000ff;
		markel_root[i + 28] = (hash->H_i[7] >> (24 - i * 8)) & 0x000000ff;
	}

}


int main() {


    unsigned char message[] = { "abcd" };
	unsigned char target[] = { 0x55, 0x01, 0x01, 0x01,
		0x01, 0x01, 0x01, 0x01, //size 32 char
		0x01, 0x01, 0x01, 0x01,
		0x01, 0x01, 0x01, 0x01,
		0x01, 0x01, 0x01, 0x01,
		0x01, 0x01, 0x01, 0x01,
		0x01, 0x01, 0x01, 0x01,
		0x01, 0x01, 0x01, 0x01 };

	// unsigned char target[] = {0x00, 0x1a, 0xf3, 0x4e,
    //             0xd4, 0xed, 0x31, 0x30, //size 32 char
    //             0x9d, 0xfd, 0xaf, 0xf3,
    //             0x45, 0xff, 0x6a, 0x23,
    //             0x70, 0xfa, 0xdd, 0xea,
    //             0xae, 0xef, 0xf3, 0xf3,
    //             0x1a, 0xd3, 0xbc, 0x32,
    //             0xde, 0xc3, 0xde, 0x31};

	unsigned char version[] = { 0x02, 0x00, 0x00, 0x00 };  //size 4 char

	unsigned char prev_block[] = { 0x17, 0x97, 0x5b, 0x97,  //size 36 char
		0xc1, 0x8e, 0xd1, 0xf7,
		0xe2, 0x55, 0xad, 0xf2,
		0x97, 0x59, 0x9b, 0x55,
		0x33, 0x0e, 0xda, 0xb8,
		0x78, 0x03, 0xc8, 0x17,
		0x01, 0x00, 0x00, 0x00,
		0x02, 0x02, 0x02, 0x02,
		0x00, 0x00, 0x00, 0x00 };

	unsigned char timestamp[] = { 0x35, 0x8b, 0x05, 0x53 }; //size 4 char

	unsigned char diff[] = { 0x53, 0x50, 0xf1, 0x19 }; // size 4 char

	HASH_VALUE markel;
	initialize(&markel);
	make_blocks(&markel, message, strlen((char*)message));

	// convert hash to char array 32 size
	unsigned char markel_root[BLOCK_SIZE];
	hash_to_char(&markel, markel_root);
	int x;
	for(x=0; x<32; x++){
		printf("%x", markel_root[x]);
		}
		printf("\n");

	//convert nonce to 32 bit or char array with size 4
	unsigned int nonce = 0;
	unsigned char nonce_4_char[4];
	nonce_4_char[0] = (nonce >> 24) & 0xFF;
	nonce_4_char[1] = (nonce >> 16) & 0xFF;
	nonce_4_char[2] = (nonce >> 8) & 0xFF;
	nonce_4_char[3] = nonce & 0xFF;

	unsigned char block_header[84];

	memcpy(block_header, version, 4);
	memcpy(&block_header[4], prev_block, 36);
	memcpy(&block_header[40], markel_root, 32);
	memcpy(&block_header[72], timestamp, 4);
	memcpy(&block_header[76], diff, 4);
	memcpy(&block_header[80], nonce_4_char, 4);


	// first time hash block header

	HASH_VALUE hash1;
	initialize(&hash1);
	make_blocks(&hash1, block_header, strlen((char*)block_header));
	unsigned char hash_val1[BLOCK_SIZE];
	hash_to_char(&hash1, hash_val1);

	HASH_VALUE hash2;
	initialize(&hash2);
	make_blocks(&hash2, hash_val1, strlen((char*)hash_val1));
	unsigned char hash_val[BLOCK_SIZE];
	hash_to_char(&hash2, hash_val);

	while (bigger_than(hash_val, target)) {

		unsigned char new_block_header[84];
		nonce++;
		nonce_4_char[0] = (nonce >> 24) & 0xFF;
		nonce_4_char[1] = (nonce >> 16) & 0xFF;
		nonce_4_char[2] = (nonce >> 8) & 0xFF;
		nonce_4_char[3] = nonce & 0xFF;

		memcpy(block_header, version, 4);
		memcpy(&block_header[4], prev_block, 36);
		memcpy(&block_header[40], hash_val, 32);
		memcpy(&block_header[72], timestamp, 4);
		memcpy(&block_header[76], diff, 4);
		memcpy(&block_header[80], nonce_4_char, 4);


		HASH_VALUE cur_hash1;
		initialize(&cur_hash1);
		make_blocks(&cur_hash1, new_block_header, strlen((char*)new_block_header));
		unsigned char cur_hash_val1[BLOCK_SIZE];
		hash_to_char(&cur_hash1, cur_hash_val1);

		HASH_VALUE cur_hash2;
		initialize(&cur_hash2);
		make_blocks(&cur_hash2, cur_hash_val1, strlen((char*)cur_hash_val1));
		unsigned char cur_hash_val2[BLOCK_SIZE];
		hash_to_char(&cur_hash2, cur_hash_val2);

		int i;
		for (i = 0; i<32; i++) {
			hash_val[i] = cur_hash_val2[i];
		}

		for(i=0; i<32; i++){
		printf("%x", hash_val[i]);
		}
		printf("\n");

		printf("%d\n", nonce);

	}

	return 0;
}