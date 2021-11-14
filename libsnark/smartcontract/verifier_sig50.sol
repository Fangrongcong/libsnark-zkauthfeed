// SPDX-License-Identifier: LGPL-3.0-only
// This file is LGPL3 Licensed
pragma solidity ^0.6.1;

/**
 * @title Elliptic curve operations on twist points for alt_bn128
 * @author Mustafa Al-Bassam (mus@musalbas.com)
 * @dev Homepage: https://github.com/musalbas/solidity-BN256G2
 */

library BN256G2 {
    uint256 internal constant FIELD_MODULUS = 0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47;
    uint256 internal constant TWISTBX = 0x2b149d40ceb8aaae81be18991be06ac3b5b4c5e559dbefa33267e6dc24a138e5;
    uint256 internal constant TWISTBY = 0x9713b03af0fed4cd2cafadeed8fdf4a74fa084e52d1852e4a2bd0685c315d2;
    uint internal constant PTXX = 0;
    uint internal constant PTXY = 1;
    uint internal constant PTYX = 2;
    uint internal constant PTYY = 3;
    uint internal constant PTZX = 4;
    uint internal constant PTZY = 5;

    /**
     * @notice Add two twist points
     * @param pt1xx Coefficient 1 of x on point 1
     * @param pt1xy Coefficient 2 of x on point 1
     * @param pt1yx Coefficient 1 of y on point 1
     * @param pt1yy Coefficient 2 of y on point 1
     * @param pt2xx Coefficient 1 of x on point 2
     * @param pt2xy Coefficient 2 of x on point 2
     * @param pt2yx Coefficient 1 of y on point 2
     * @param pt2yy Coefficient 2 of y on point 2
     * @return (pt3xx, pt3xy, pt3yx, pt3yy)
     */
    function ECTwistAdd(
        uint256 pt1xx, uint256 pt1xy,
        uint256 pt1yx, uint256 pt1yy,
        uint256 pt2xx, uint256 pt2xy,
        uint256 pt2yx, uint256 pt2yy
    ) public view returns (
        uint256, uint256,
        uint256, uint256
    ) {
        if (
            pt1xx == 0 && pt1xy == 0 &&
            pt1yx == 0 && pt1yy == 0
        ) {
            if (!(
                pt2xx == 0 && pt2xy == 0 &&
                pt2yx == 0 && pt2yy == 0
            )) {
                assert(_isOnCurve(
                    pt2xx, pt2xy,
                    pt2yx, pt2yy
                ));
            }
            return (
                pt2xx, pt2xy,
                pt2yx, pt2yy
            );
        } else if (
            pt2xx == 0 && pt2xy == 0 &&
            pt2yx == 0 && pt2yy == 0
        ) {
            assert(_isOnCurve(
                pt1xx, pt1xy,
                pt1yx, pt1yy
            ));
            return (
                pt1xx, pt1xy,
                pt1yx, pt1yy
            );
        }

        assert(_isOnCurve(
            pt1xx, pt1xy,
            pt1yx, pt1yy
        ));
        assert(_isOnCurve(
            pt2xx, pt2xy,
            pt2yx, pt2yy
        ));

        uint256[6] memory pt3 = _ECTwistAddJacobian(
            pt1xx, pt1xy,
            pt1yx, pt1yy,
            1,     0,
            pt2xx, pt2xy,
            pt2yx, pt2yy,
            1,     0
        );

        return _fromJacobian(
            pt3[PTXX], pt3[PTXY],
            pt3[PTYX], pt3[PTYY],
            pt3[PTZX], pt3[PTZY]
        );
    }

    /**
     * @notice Multiply a twist point by a scalar
     * @param s     Scalar to multiply by
     * @param pt1xx Coefficient 1 of x
     * @param pt1xy Coefficient 2 of x
     * @param pt1yx Coefficient 1 of y
     * @param pt1yy Coefficient 2 of y
     * @return (pt2xx, pt2xy, pt2yx, pt2yy)
     */
    function ECTwistMul(
        uint256 s,
        uint256 pt1xx, uint256 pt1xy,
        uint256 pt1yx, uint256 pt1yy
    ) public view returns (
        uint256, uint256,
        uint256, uint256
    ) {
        uint256 pt1zx = 1;
        if (
            pt1xx == 0 && pt1xy == 0 &&
            pt1yx == 0 && pt1yy == 0
        ) {
            pt1xx = 1;
            pt1yx = 1;
            pt1zx = 0;
        } else {
            assert(_isOnCurve(
                pt1xx, pt1xy,
                pt1yx, pt1yy
            ));
        }

        uint256[6] memory pt2 = _ECTwistMulJacobian(
            s,
            pt1xx, pt1xy,
            pt1yx, pt1yy,
            pt1zx, 0
        );

        return _fromJacobian(
            pt2[PTXX], pt2[PTXY],
            pt2[PTYX], pt2[PTYY],
            pt2[PTZX], pt2[PTZY]
        );
    }

    /**
     * @notice Get the field modulus
     * @return The field modulus
     */
    function GetFieldModulus() public pure returns (uint256) {
        return FIELD_MODULUS;
    }

    function submod(uint256 a, uint256 b, uint256 n) internal pure returns (uint256) {
        return addmod(a, n - b, n);
    }

    function _FQ2Mul(
        uint256 xx, uint256 xy,
        uint256 yx, uint256 yy
    ) internal pure returns (uint256, uint256) {
        return (
            submod(mulmod(xx, yx, FIELD_MODULUS), mulmod(xy, yy, FIELD_MODULUS), FIELD_MODULUS),
            addmod(mulmod(xx, yy, FIELD_MODULUS), mulmod(xy, yx, FIELD_MODULUS), FIELD_MODULUS)
        );
    }

    function _FQ2Muc(
        uint256 xx, uint256 xy,
        uint256 c
    ) internal pure returns (uint256, uint256) {
        return (
            mulmod(xx, c, FIELD_MODULUS),
            mulmod(xy, c, FIELD_MODULUS)
        );
    }

    function _FQ2Add(
        uint256 xx, uint256 xy,
        uint256 yx, uint256 yy
    ) internal pure returns (uint256, uint256) {
        return (
            addmod(xx, yx, FIELD_MODULUS),
            addmod(xy, yy, FIELD_MODULUS)
        );
    }

    function _FQ2Sub(
        uint256 xx, uint256 xy,
        uint256 yx, uint256 yy
    ) internal pure returns (uint256 rx, uint256 ry) {
        return (
            submod(xx, yx, FIELD_MODULUS),
            submod(xy, yy, FIELD_MODULUS)
        );
    }

    function _FQ2Div(
        uint256 xx, uint256 xy,
        uint256 yx, uint256 yy
    ) internal view returns (uint256, uint256) {
        (yx, yy) = _FQ2Inv(yx, yy);
        return _FQ2Mul(xx, xy, yx, yy);
    }

    function _FQ2Inv(uint256 x, uint256 y) internal view returns (uint256, uint256) {
        uint256 inv = _modInv(addmod(mulmod(y, y, FIELD_MODULUS), mulmod(x, x, FIELD_MODULUS), FIELD_MODULUS), FIELD_MODULUS);
        return (
            mulmod(x, inv, FIELD_MODULUS),
            FIELD_MODULUS - mulmod(y, inv, FIELD_MODULUS)
        );
    }

    function _isOnCurve(
        uint256 xx, uint256 xy,
        uint256 yx, uint256 yy
    ) internal pure returns (bool) {
        uint256 yyx;
        uint256 yyy;
        uint256 xxxx;
        uint256 xxxy;
        (yyx, yyy) = _FQ2Mul(yx, yy, yx, yy);
        (xxxx, xxxy) = _FQ2Mul(xx, xy, xx, xy);
        (xxxx, xxxy) = _FQ2Mul(xxxx, xxxy, xx, xy);
        (yyx, yyy) = _FQ2Sub(yyx, yyy, xxxx, xxxy);
        (yyx, yyy) = _FQ2Sub(yyx, yyy, TWISTBX, TWISTBY);
        return yyx == 0 && yyy == 0;
    }

    function _modInv(uint256 a, uint256 n) internal view returns (uint256 result) {
        bool success;
        assembly {
            let freemem := mload(0x40)
            mstore(freemem, 0x20)
            mstore(add(freemem,0x20), 0x20)
            mstore(add(freemem,0x40), 0x20)
            mstore(add(freemem,0x60), a)
            mstore(add(freemem,0x80), sub(n, 2))
            mstore(add(freemem,0xA0), n)
            success := staticcall(sub(gas(), 2000), 5, freemem, 0xC0, freemem, 0x20)
            result := mload(freemem)
        }
        require(success);
    }

    function _fromJacobian(
        uint256 pt1xx, uint256 pt1xy,
        uint256 pt1yx, uint256 pt1yy,
        uint256 pt1zx, uint256 pt1zy
    ) internal view returns (
        uint256 pt2xx, uint256 pt2xy,
        uint256 pt2yx, uint256 pt2yy
    ) {
        uint256 invzx;
        uint256 invzy;
        (invzx, invzy) = _FQ2Inv(pt1zx, pt1zy);
        (pt2xx, pt2xy) = _FQ2Mul(pt1xx, pt1xy, invzx, invzy);
        (pt2yx, pt2yy) = _FQ2Mul(pt1yx, pt1yy, invzx, invzy);
    }

    function _ECTwistAddJacobian(
        uint256 pt1xx, uint256 pt1xy,
        uint256 pt1yx, uint256 pt1yy,
        uint256 pt1zx, uint256 pt1zy,
        uint256 pt2xx, uint256 pt2xy,
        uint256 pt2yx, uint256 pt2yy,
        uint256 pt2zx, uint256 pt2zy) internal pure returns (uint256[6] memory pt3) {
            if (pt1zx == 0 && pt1zy == 0) {
                (
                    pt3[PTXX], pt3[PTXY],
                    pt3[PTYX], pt3[PTYY],
                    pt3[PTZX], pt3[PTZY]
                ) = (
                    pt2xx, pt2xy,
                    pt2yx, pt2yy,
                    pt2zx, pt2zy
                );
                return pt3;
            } else if (pt2zx == 0 && pt2zy == 0) {
                (
                    pt3[PTXX], pt3[PTXY],
                    pt3[PTYX], pt3[PTYY],
                    pt3[PTZX], pt3[PTZY]
                ) = (
                    pt1xx, pt1xy,
                    pt1yx, pt1yy,
                    pt1zx, pt1zy
                );
                return pt3;
            }

            (pt2yx,     pt2yy)     = _FQ2Mul(pt2yx, pt2yy, pt1zx, pt1zy); // U1 = y2 * z1
            (pt3[PTYX], pt3[PTYY]) = _FQ2Mul(pt1yx, pt1yy, pt2zx, pt2zy); // U2 = y1 * z2
            (pt2xx,     pt2xy)     = _FQ2Mul(pt2xx, pt2xy, pt1zx, pt1zy); // V1 = x2 * z1
            (pt3[PTZX], pt3[PTZY]) = _FQ2Mul(pt1xx, pt1xy, pt2zx, pt2zy); // V2 = x1 * z2

            if (pt2xx == pt3[PTZX] && pt2xy == pt3[PTZY]) {
                if (pt2yx == pt3[PTYX] && pt2yy == pt3[PTYY]) {
                    (
                        pt3[PTXX], pt3[PTXY],
                        pt3[PTYX], pt3[PTYY],
                        pt3[PTZX], pt3[PTZY]
                    ) = _ECTwistDoubleJacobian(pt1xx, pt1xy, pt1yx, pt1yy, pt1zx, pt1zy);
                    return pt3;
                }
                (
                    pt3[PTXX], pt3[PTXY],
                    pt3[PTYX], pt3[PTYY],
                    pt3[PTZX], pt3[PTZY]
                ) = (
                    1, 0,
                    1, 0,
                    0, 0
                );
                return pt3;
            }

            (pt2zx,     pt2zy)     = _FQ2Mul(pt1zx, pt1zy, pt2zx,     pt2zy);     // W = z1 * z2
            (pt1xx,     pt1xy)     = _FQ2Sub(pt2yx, pt2yy, pt3[PTYX], pt3[PTYY]); // U = U1 - U2
            (pt1yx,     pt1yy)     = _FQ2Sub(pt2xx, pt2xy, pt3[PTZX], pt3[PTZY]); // V = V1 - V2
            (pt1zx,     pt1zy)     = _FQ2Mul(pt1yx, pt1yy, pt1yx,     pt1yy);     // V_squared = V * V
            (pt2yx,     pt2yy)     = _FQ2Mul(pt1zx, pt1zy, pt3[PTZX], pt3[PTZY]); // V_squared_times_V2 = V_squared * V2
            (pt1zx,     pt1zy)     = _FQ2Mul(pt1zx, pt1zy, pt1yx,     pt1yy);     // V_cubed = V * V_squared
            (pt3[PTZX], pt3[PTZY]) = _FQ2Mul(pt1zx, pt1zy, pt2zx,     pt2zy);     // newz = V_cubed * W
            (pt2xx,     pt2xy)     = _FQ2Mul(pt1xx, pt1xy, pt1xx,     pt1xy);     // U * U
            (pt2xx,     pt2xy)     = _FQ2Mul(pt2xx, pt2xy, pt2zx,     pt2zy);     // U * U * W
            (pt2xx,     pt2xy)     = _FQ2Sub(pt2xx, pt2xy, pt1zx,     pt1zy);     // U * U * W - V_cubed
            (pt2zx,     pt2zy)     = _FQ2Muc(pt2yx, pt2yy, 2);                    // 2 * V_squared_times_V2
            (pt2xx,     pt2xy)     = _FQ2Sub(pt2xx, pt2xy, pt2zx,     pt2zy);     // A = U * U * W - V_cubed - 2 * V_squared_times_V2
            (pt3[PTXX], pt3[PTXY]) = _FQ2Mul(pt1yx, pt1yy, pt2xx,     pt2xy);     // newx = V * A
            (pt1yx,     pt1yy)     = _FQ2Sub(pt2yx, pt2yy, pt2xx,     pt2xy);     // V_squared_times_V2 - A
            (pt1yx,     pt1yy)     = _FQ2Mul(pt1xx, pt1xy, pt1yx,     pt1yy);     // U * (V_squared_times_V2 - A)
            (pt1xx,     pt1xy)     = _FQ2Mul(pt1zx, pt1zy, pt3[PTYX], pt3[PTYY]); // V_cubed * U2
            (pt3[PTYX], pt3[PTYY]) = _FQ2Sub(pt1yx, pt1yy, pt1xx,     pt1xy);     // newy = U * (V_squared_times_V2 - A) - V_cubed * U2
    }

    function _ECTwistDoubleJacobian(
        uint256 pt1xx, uint256 pt1xy,
        uint256 pt1yx, uint256 pt1yy,
        uint256 pt1zx, uint256 pt1zy
    ) internal pure returns (
        uint256 pt2xx, uint256 pt2xy,
        uint256 pt2yx, uint256 pt2yy,
        uint256 pt2zx, uint256 pt2zy
    ) {
        (pt2xx, pt2xy) = _FQ2Muc(pt1xx, pt1xy, 3);            // 3 * x
        (pt2xx, pt2xy) = _FQ2Mul(pt2xx, pt2xy, pt1xx, pt1xy); // W = 3 * x * x
        (pt1zx, pt1zy) = _FQ2Mul(pt1yx, pt1yy, pt1zx, pt1zy); // S = y * z
        (pt2yx, pt2yy) = _FQ2Mul(pt1xx, pt1xy, pt1yx, pt1yy); // x * y
        (pt2yx, pt2yy) = _FQ2Mul(pt2yx, pt2yy, pt1zx, pt1zy); // B = x * y * S
        (pt1xx, pt1xy) = _FQ2Mul(pt2xx, pt2xy, pt2xx, pt2xy); // W * W
        (pt2zx, pt2zy) = _FQ2Muc(pt2yx, pt2yy, 8);            // 8 * B
        (pt1xx, pt1xy) = _FQ2Sub(pt1xx, pt1xy, pt2zx, pt2zy); // H = W * W - 8 * B
        (pt2zx, pt2zy) = _FQ2Mul(pt1zx, pt1zy, pt1zx, pt1zy); // S_squared = S * S
        (pt2yx, pt2yy) = _FQ2Muc(pt2yx, pt2yy, 4);            // 4 * B
        (pt2yx, pt2yy) = _FQ2Sub(pt2yx, pt2yy, pt1xx, pt1xy); // 4 * B - H
        (pt2yx, pt2yy) = _FQ2Mul(pt2yx, pt2yy, pt2xx, pt2xy); // W * (4 * B - H)
        (pt2xx, pt2xy) = _FQ2Muc(pt1yx, pt1yy, 8);            // 8 * y
        (pt2xx, pt2xy) = _FQ2Mul(pt2xx, pt2xy, pt1yx, pt1yy); // 8 * y * y
        (pt2xx, pt2xy) = _FQ2Mul(pt2xx, pt2xy, pt2zx, pt2zy); // 8 * y * y * S_squared
        (pt2yx, pt2yy) = _FQ2Sub(pt2yx, pt2yy, pt2xx, pt2xy); // newy = W * (4 * B - H) - 8 * y * y * S_squared
        (pt2xx, pt2xy) = _FQ2Muc(pt1xx, pt1xy, 2);            // 2 * H
        (pt2xx, pt2xy) = _FQ2Mul(pt2xx, pt2xy, pt1zx, pt1zy); // newx = 2 * H * S
        (pt2zx, pt2zy) = _FQ2Mul(pt1zx, pt1zy, pt2zx, pt2zy); // S * S_squared
        (pt2zx, pt2zy) = _FQ2Muc(pt2zx, pt2zy, 8);            // newz = 8 * S * S_squared
    }

    function _ECTwistMulJacobian(
        uint256 d,
        uint256 pt1xx, uint256 pt1xy,
        uint256 pt1yx, uint256 pt1yy,
        uint256 pt1zx, uint256 pt1zy
    ) internal pure returns (uint256[6] memory pt2) {
        while (d != 0) {
            if ((d & 1) != 0) {
                pt2 = _ECTwistAddJacobian(
                    pt2[PTXX], pt2[PTXY],
                    pt2[PTYX], pt2[PTYY],
                    pt2[PTZX], pt2[PTZY],
                    pt1xx, pt1xy,
                    pt1yx, pt1yy,
                    pt1zx, pt1zy);
            }
            (
                pt1xx, pt1xy,
                pt1yx, pt1yy,
                pt1zx, pt1zy
            ) = _ECTwistDoubleJacobian(
                pt1xx, pt1xy,
                pt1yx, pt1yy,
                pt1zx, pt1zy
            );

            d = d / 2;
        }
    }
}



// This file is MIT Licensed.
//
// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


// This file is MIT Licensed.
//
// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
pragma solidity ^0.6.1;
library Pairing {
    struct G1Point {
        uint X;
        uint Y;
    }
    // Encoding of field elements is: X[0] * z + X[1]
    struct G2Point {
        uint[2] X;
        uint[2] Y;
    }
    /// @return the generator of G1
    function P1() pure internal returns (G1Point memory) {
        return G1Point(1, 2);
    }
    /// @return the generator of G2
    function P2() pure internal returns (G2Point memory) {
        return G2Point(
            [10857046999023057135944570762232829481370756359578518086990519993285655852781,
             11559732032986387107991004021392285783925812861821192530917403151452391805634],
            [8495653923123431417604973247489272438418190587263600148770280649306958101930,
             4082367875863433681332203403145435568316851327593401208105741076214120093531]
        );
    }
    /// @return the negation of p, i.e. p.addition(p.negate()) should be zero.
    function negate(G1Point memory p) pure internal returns (G1Point memory) {
        // The prime q in the base field F_q for G1
        uint q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
        if (p.X == 0 && p.Y == 0)
            return G1Point(0, 0);
        return G1Point(p.X, q - (p.Y % q));
    }
    /// @return r the sum of two points of G1
    function addition(G1Point memory p1, G1Point memory p2) internal view returns (G1Point memory r) {
        uint[4] memory input;
        input[0] = p1.X;
        input[1] = p1.Y;
        input[2] = p2.X;
        input[3] = p2.Y;
        bool success;
        assembly {
            success := staticcall(sub(gas(), 2000), 6, input, 0xc0, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success);
    }
    /// @return r the sum of two points of G2
    function addition(G2Point memory p1, G2Point memory p2) internal view returns (G2Point memory r) {
        (r.X[0], r.X[1], r.Y[0], r.Y[1]) = BN256G2.ECTwistAdd(p1.X[0],p1.X[1],p1.Y[0],p1.Y[1],p2.X[0],p2.X[1],p2.Y[0],p2.Y[1]);
    }
    /// @return r the product of a point on G1 and a scalar, i.e.
    /// p == p.scalar_mul(1) and p.addition(p) == p.scalar_mul(2) for all points p.
    function scalar_mul(G1Point memory p, uint s) internal view returns (G1Point memory r) {
        uint[3] memory input;
        input[0] = p.X;
        input[1] = p.Y;
        input[2] = s;
        bool success;
        assembly {
            success := staticcall(sub(gas(), 2000), 7, input, 0x80, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require (success);
    }
    /// @return the result of computing the pairing check
    /// e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
    /// For example pairing([P1(), P1().negate()], [P2(), P2()]) should
    /// return true.
    function pairing(G1Point[] memory p1, G2Point[] memory p2) internal view returns (bool) {
        require(p1.length == p2.length);
        uint elements = p1.length;
        uint inputSize = elements * 6;
        uint[] memory input = new uint[](inputSize);
        for (uint i = 0; i < elements; i++)
        {
            input[i * 6 + 0] = p1[i].X;
            input[i * 6 + 1] = p1[i].Y;
            input[i * 6 + 2] = p2[i].X[1];
            input[i * 6 + 3] = p2[i].X[0];
            input[i * 6 + 4] = p2[i].Y[1];
            input[i * 6 + 5] = p2[i].Y[0];
        }
        uint[1] memory out;
        bool success;
        assembly {
            success := staticcall(sub(gas(), 2000), 8, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success);
        return out[0] != 0;
    }
    /// Convenience method for a pairing check for two pairs.
    function pairingProd2(G1Point memory a1, G2Point memory a2, G1Point memory b1, G2Point memory b2) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](2);
        G2Point[] memory p2 = new G2Point[](2);
        p1[0] = a1;
        p1[1] = b1;
        p2[0] = a2;
        p2[1] = b2;
        return pairing(p1, p2);
    }
    /// Convenience method for a pairing check for three pairs.
    function pairingProd3(
            G1Point memory a1, G2Point memory a2,
            G1Point memory b1, G2Point memory b2,
            G1Point memory c1, G2Point memory c2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](3);
        G2Point[] memory p2 = new G2Point[](3);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        return pairing(p1, p2);
    }
    /// Convenience method for a pairing check for four pairs.
    function pairingProd4(
            G1Point memory a1, G2Point memory a2,
            G1Point memory b1, G2Point memory b2,
            G1Point memory c1, G2Point memory c2,
            G1Point memory d1, G2Point memory d2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](4);
        G2Point[] memory p2 = new G2Point[](4);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p1[3] = d1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        p2[3] = d2;
        return pairing(p1, p2);
    }
}

// This file is MIT Licensed.
//
// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
pragma solidity ^0.6.1;

library GetVK200 {
    using Pairing for *;
    function getvk(uint m1, uint n1, uint32[] memory iinput) public view returns (uint x1, uint  y1) {
        Pairing.G1Point[] memory data = new Pairing.G1Point[](60);
        data[0] = Pairing.G1Point(uint256(0x138ee0059dcce64fc49fff582890153f08ad5cd7d7ea9b5ee9b9ee6758923111), uint256(0x13806556b14c8d4b5a8d737ebdb6c781121747bfaa1f31e8730ad880c14c3bb5));
data[0] = Pairing.G1Point(uint256(0x22a590e8f02733996e1959c736a8ef935f8a69a7afe9f1d11a7743924717fa50), uint256(0x00df7174480385ab685caf597f144987006b7722a645efcdde511ca7e8ab1ab9));
data[1] = Pairing.G1Point(uint256(0x0ea324649e1aee3d6a45cd2fa9ce19603475d520805a2037699852cd8ee23c50), uint256(0x0366b02a666a204f231b603271f80b25fd40d57cc35867928bbaeeb206f1213f));
data[2] = Pairing.G1Point(uint256(0x15854ed545acf7a6a0ea78a65a4db7d1e10383dcda029e4492e00a22e3511258), uint256(0x03521fd7bdb8440644c70fd5ce782d255ce107095b3fb3241082d6fe3efcdddb));
data[3] = Pairing.G1Point(uint256(0x2bf4f10a060e8beb6b7ef19610d9e826187292f43ce67db036239c8a8d124c35), uint256(0x099bb7b821d1333c92f137263ae1ec8c997f5708e135b3f27eb13cf39a9d8b85));
data[4] = Pairing.G1Point(uint256(0x15f1a6db310b9ee15db9086e5cae98f39743ee08a04b9251bebd4b3d62c78183), uint256(0x26767e66ac083d497eb1ae626d5e660001561a1cdb79a9372a048646bbc71c77));
data[5] = Pairing.G1Point(uint256(0x200b11c8e121289c2bb77f45de9c95d634910fd81f337e4ca6c5560fb842f56b), uint256(0x22af1fd6ec48c50f99154c061f7505d44429b24bce480a6a9e78d6f2d2f6bd39));
data[6] = Pairing.G1Point(uint256(0x0397303042b70d56e9732cb5ae69233e15131d9223e9a58bbc2f4e9e0991804c), uint256(0x0281f0846e0e377f8e87899e642f4d3cc97c89fa0466996ffa313e9cf0913b77));
data[7] = Pairing.G1Point(uint256(0x2268d5688c974bdeaa4a4a165b8fd5ebd4156dde935fc3e985b511b0a51f4a29), uint256(0x051bac8e89bbffa12ea2fbc36973a11f4b7615b29a5578b42efef40a25a17f70));
data[8] = Pairing.G1Point(uint256(0x0523a29e40a11b709da699aa3889db3d6432edad1ce0f8524b1b237187f662bd), uint256(0x0b9ddb7642dcb62ee6db6340121096bddda8b8e136eb48b536053a1d49ed96c5));
data[9] = Pairing.G1Point(uint256(0x1677a73412b17247ee3f57239bdb172a04dc8f85f2c5e863deec5ef07308f50d), uint256(0x11a5af748064b5f81d8f5af1ac2e16a03048ee156462a188c0618e0dcebf5669));
data[10] = Pairing.G1Point(uint256(0x006644cf131a04ffa0dbf42b3fd2922da3c061b7a924e841d0c5e980ac215a00), uint256(0x1d537026d2f761a427b7aa06b2f113f63fa7d1f426a207339d5a1d70c34445a7));
data[11] = Pairing.G1Point(uint256(0x2c7182f789800665d7bead307c1312cbe976dfc340707c55f24ec8db15654563), uint256(0x1a0af395d3c1adf81ea2752642c8e04fc4c8a51969214db5629144bbea6cda1c));
data[12] = Pairing.G1Point(uint256(0x2b2aec0a310380bfbab3ef7c8fbef19d0235d67d93c060e04e09a094db7fcfd0), uint256(0x1220520d3eac941f8e747b35244315511bb535474c67f5480d73677a04c3242b));
data[13] = Pairing.G1Point(uint256(0x011cbafaac000460baf54fbf5f069d1a1cee8e6e98c1e68a4c6b403c528cdfa4), uint256(0x1b39b68019034232b65040e2bc7a6931e0512f7a07eccb613de19c3262b331a8));
data[14] = Pairing.G1Point(uint256(0x0abfc6086b42a7adc6f7c2e3633b3b28dfa169ed09a72342ab56869ba95abc0b), uint256(0x2fc7c2b2eb2aae01440988448fb39c58a4f3dcee72a1e82ffe45b65c56e94a76));
data[15] = Pairing.G1Point(uint256(0x10d6926631f2d8778a66db6b897c783de2155b2bc04ddee374a2e8bedfc9c45b), uint256(0x0cf0146a1e3f9ca50627941c36b1f92a35615ede365b31c246d8fed3a9b2df6b));
data[16] = Pairing.G1Point(uint256(0x09daa30dad5de03175f0a9e89e81aa428b66b2978e8869474230ca5b5a929052), uint256(0x2d94b1cd4cc18db855f7bc6b93577275400387b492354170a9595931cba9d827));
data[17] = Pairing.G1Point(uint256(0x04af1fba9ecd882e575fa5c38ea3e4fbb1b468018b4a31fccae17fbb78f5620f), uint256(0x1a88d646ed9a2c753782a272a3fbef10c3989f2648cb81a957b1fc9baff188f2));
data[18] = Pairing.G1Point(uint256(0x0099a5b87dc5412e92fb1382ed5cbdc95b265f64315715495adcdf4c76369d0c), uint256(0x2eaf4a29f13418b8366d6ca3af72dbece082bf0971ffe697a900f85430ab651c));
data[19] = Pairing.G1Point(uint256(0x008495da2d698e3a504a56b4767d01417f08ee80a593fca9490edbdab79dd0e1), uint256(0x238e35b1d1c05639c29b35b8be35fd58d3078dfcf7e0e963583c9f6bae0e5e9d));
data[20] = Pairing.G1Point(uint256(0x1c4cbb0d736f35ae8f113173ec60d102cbfc846900e74a33bee473e167b8b0e5), uint256(0x112f69eff91a15f1ab280f061bbb1d56298eae7f172fafc619b893748b440c82));
data[21] = Pairing.G1Point(uint256(0x117bf996e20971e3951fe1edebb996de5ed417498419bd79c549ef3d40c15deb), uint256(0x15831164f4cc0766593174a408929f5b82a34310e72333ead03736b1a5b01d6a));
data[22] = Pairing.G1Point(uint256(0x2fb5d1820adf2acbdc20a4653cd66d3c5dc4ed6e99d24b5967c3986a57d06d91), uint256(0x054d0daa9aa1f6d69821c6d3e8e495f140570172d0c63d3d0087343ab7d56ab9));
data[23] = Pairing.G1Point(uint256(0x0fb0da571719b3d15a43f91d1531960268315940e0bb2b5404ad82921c82408a), uint256(0x1354998910f8f2445c52d1a47a4e3e7428e5714953e64c3d37d6495829c1405f));
data[24] = Pairing.G1Point(uint256(0x221f655c85ee31290f8d217f248dc1f82ecfdfd62b607137b5b4310f80f1a4e7), uint256(0x20e762f139f17a8a8fe41a335e5378d25caaf231619445a7703c3396f1fce43c));
data[25] = Pairing.G1Point(uint256(0x0d3f3d192b33fd16abef0326da8ec1082155edf3275f76ee7ab0ec37b7d0612d), uint256(0x2bb2b2a36e9b51fa2fb6023b63191b9fe4ef8d4058b97a713e724f1603a3ca9c));
data[26] = Pairing.G1Point(uint256(0x11bc2e7e795f882ac02e30a208be8f2782028a1c1ef62e6fcc897573c62b01ff), uint256(0x040971de9a2af4f92805425b3f8a40be16cf9a2e298c9bcdc383c56536fb109b));
data[27] = Pairing.G1Point(uint256(0x0822f7dfe0b80f6b800b300806e76630cb53586f6c0150468edc54558591c976), uint256(0x07284764685ff37236917329b2475512da3bc8256d60a1cee380d71f6dd120f5));
data[28] = Pairing.G1Point(uint256(0x2702daf79f010f3ac3c9e2ad0bc2d43711beae87f496fb0edc3d199e0a0bf1d1), uint256(0x192610822b01259ecbeb33f66780d6aa70f01603c824338d8ac2bf1e734c20fb));
data[29] = Pairing.G1Point(uint256(0x25d0001a3e3df6ad9b7e1494c2c0885fa8e84fe6f5f0424785ba3994a802d39e), uint256(0x119a615f618c449bf4b4b013d05b58708f557251f6bcce7050b94c88852005b6));
data[30] = Pairing.G1Point(uint256(0x12ae434dccd701496d5d1b32f15b2d7691135eb357f8fe2380e06d283f7ed76b), uint256(0x2db618cde747496e4c0e171bf079bcbcfe6c4244e215b6ee46c5f35d4fc77166));
data[31] = Pairing.G1Point(uint256(0x0dd83b746f659373ef8036480bf29cc9b5de47256da02870e29b42c8ff97c1ea), uint256(0x27a26772ef3bce2731a37b6b9173e9248736fbe208f7f8ad081bf68fc915d3e0));
data[32] = Pairing.G1Point(uint256(0x071400c6b4045bc445d31b72994da8b5a94667df5d4727e9d432b6234f4b4d0b), uint256(0x0edffd2c90b90f470b34a0d794965ad71fa8f0c86f13fd6432791cf566dc4bc4));
data[33] = Pairing.G1Point(uint256(0x2de39ca966fb8d0df7e21e1b3ac6feb1da770a78727ef3a5d3a33ee77b4cd496), uint256(0x28ebd69a174e9721382d34e1630a8bf30a30f5eeee9e43f62f3590b7fc40407f));
data[34] = Pairing.G1Point(uint256(0x18ec94171f89a5d2f6c2537252cf938625a97474dabfd3363ca641108cb69572), uint256(0x084472693708c05569174d3914189caccd4c75e8f3c6ba18982d1849ad884489));
data[35] = Pairing.G1Point(uint256(0x05c218dba5d0b122da6d50395e2e9bf32425a930da78e74729b09198b5a14660), uint256(0x05eb2577e9f85fb4e5c5aef9052cdb02146bf0183014fc60adf1508d9f0ef40e));
data[36] = Pairing.G1Point(uint256(0x25e382d7d6894c87d5090c7b0802cbcca361184969a6750ec90d02949f5dc53f), uint256(0x06a04a4cf05da23f65c6e791b3a78614bcfb386180a9d67d57d083c5bc6e0222));
data[37] = Pairing.G1Point(uint256(0x25a1272a1d237e922d6dcd1fd3e6db7262a5413f0b4191ba78911e72448a46f6), uint256(0x0194f70dd95de130cbb88d352591e6339d9a16f2f1f729c0800c72582b97ffb9));
data[38] = Pairing.G1Point(uint256(0x0845aeaa2d63b3c88f7d65e3cd8c25165dfb58fd0f5394117cf279c2e4ea19cb), uint256(0x081e712fea3f3d5b70e6a0ef8bed5e14b77cdded33ce3388ba6b3f05ad7f9470));
data[39] = Pairing.G1Point(uint256(0x1a2416737d5ed7bfa9a60d368c6be80e6a91333ddc1a002a89e31c364579aa4d), uint256(0x2c075bf4e04495b2ea0e1c3338c25b10fa90b035f42a778ff472f066d03ec3ed));
data[40] = Pairing.G1Point(uint256(0x12ed527f5b33a7d77b09b53ace91a34b2abc50d0a249da53c26832cd23d9674e), uint256(0x27aa4122d0b534ba963f67f9946d55aa1c17bbc1973a98ecc3c97800037bfd8f));
data[41] = Pairing.G1Point(uint256(0x303a026342b366712aa1621c1c00e7c69cb6b3cc6df215bd743b1387e8c2bc66), uint256(0x2f2e2d6db60a3d1812a860fc9be3ff65c2292867b97a07c24c1d9bd88c4766a2));
data[42] = Pairing.G1Point(uint256(0x10e27ffd0619bbeca8cea6f3beaa0fa99406545f7476fe0a633860d1c1bc3dde), uint256(0x04f75628bb13d377be084b66ad0f795fea7df4e8089025f2f03a94bad397904b));
data[43] = Pairing.G1Point(uint256(0x1e41b729b594bf44af9d0700d043492246ac1941493f3155c6268a4cfd33ba56), uint256(0x09e1271c6fb4d89db7077a642f291f42b3f7e701953f6f16fffefadcd5f3a7ef));
data[44] = Pairing.G1Point(uint256(0x0f2f8818ff32b7ac0d5cd0979158560fd6cbbff1fdd3e893d98aed1b637c5e1f), uint256(0x1a9eccdaa05f39d09dcce1ecae46491679726669ace450cabd769e5f8a4539ca));
data[45] = Pairing.G1Point(uint256(0x25b22d11b1627338610b78fd7ef36704205d8b6c1d777694cb3efff0ca625f1c), uint256(0x0b263a942163d0eba893af3abcb5491039b68c5a3731173aa5882e7cecba2f28));
data[46] = Pairing.G1Point(uint256(0x2e66d4f7358678e9621d1c3a81065a228bcccd7cbb6847e93467899f67432eea), uint256(0x20644f012555c48c8149bfb900439039ce4a4c1462b4ab6cb903baaddf2c8f53));
data[47] = Pairing.G1Point(uint256(0x0c948602d095ccde3ce3b8f1d820cf4cbd41b787a7e747e5627c23c82a876141), uint256(0x231dcc827d70359d435f7863a2fc36bfd10f2e019918b0feb61209dc6b4510e4));
data[48] = Pairing.G1Point(uint256(0x1c953a4dec618920898f2d6bb0f14e2e7a26c23d132efe99764a7557805c8efd), uint256(0x11b826c28083a1a6f8900c32f6402512528de7470aed20d538dbf0ff7b65f0de));
data[49] = Pairing.G1Point(uint256(0x2ef7b618ef99eb6971a88180e67b8a467bbb0390242c4e9860e33696c95830ad), uint256(0x1a47e5f9c582ef6579d513d337abc556d9317e9069c038293d48f8b9656738b0));
data[50] = Pairing.G1Point(uint256(0x189e74f438560445ba9d0e24cca858086a69f823d078ba04a4b8d3b70437d4a1), uint256(0x1417ef653eb75289b5ac3ced9778cd69d83c69eabe97c45a83f15ca4d22b293a));
data[51] = Pairing.G1Point(uint256(0x12d04dbbf8f96783c20f88d6e7a37a5b0f322ea4e42125f46cd12fcfb0b02541), uint256(0x1d5f239f334ff3b8813431be24e172ad18d477b71cc9ca5f35c5f4a2bfd816a0));
data[52] = Pairing.G1Point(uint256(0x20e2601599dc060ae22531524c127646d8de0ef43d192a46799bb2d97b3228eb), uint256(0x0915cacc24ec9cf3e3d776bbd9d0eb6535e39a6c7f6b890bb7a947f2303db9e8));
data[53] = Pairing.G1Point(uint256(0x0fa536dc2dda7c620936b7435fe8af5ecd385658495c055d8e4f45c25194a64c), uint256(0x1ae97f6dee80e746f8b1e247df247ff2242b957dad496aedd7f51589566b2709));
data[54] = Pairing.G1Point(uint256(0x195e1a044d496f7b05d5c148528711ef6474f681f038ba1bb9d1b8906235ea60), uint256(0x10d1d98bd405b4b79c68c7e70d2f6fcaec07bfc08606ea23427acf6f73c02f71));
data[55] = Pairing.G1Point(uint256(0x0a3ae1ebe03095b20f03159d5a7c98505454fa494fa5ec7a6f73b728006c6878), uint256(0x2a614d1493d7f16bebafbab031e2d978af68537dc5339b603aefc8a26b81db01));
data[56] = Pairing.G1Point(uint256(0x21562f72a0162ca2e12f568cdc33cad933f703ff42a2d3c9f848a6a229477fbf), uint256(0x1e3d37f9feb5c7d162de0204ab51e35c3c627f681930bfca098e7b28a971e328));
data[57] = Pairing.G1Point(uint256(0x0b0c8530f57c4a5e4065f5d850c95aa90049336509691692884fd032603690e9), uint256(0x276f2995db066c5a6bc4d0fdaae491592d62e940e4968e6ef7f926d204e1a452));
data[58] = Pairing.G1Point(uint256(0x1c64daef0e89e9793ebc4328f0ef75fa93d8a761b1dd39d4c4a67f85b8f53c0b), uint256(0x14ec79fef5ca12b3641c7e76ca4f51d99c5feab53714047f020872e484c1bc6a));
data[59] = Pairing.G1Point(uint256(0x18c9456bfd5e037e189e0ce2a3b6e939a8ce6c30ab1d00fb2f1d50186b674d67), uint256(0x13bf587680b040e47e8d9ad33bb117cf5fc490fa4845cd410ac1bccc0ffe38d9));
        Pairing.G1Point memory vk_x1 = Pairing.G1Point(m1, n1);
        for (uint i = 0; i < iinput.length; i++) {
            vk_x1 = Pairing.addition(vk_x1, Pairing.scalar_mul(data[i], uint(iinput[i])));
        }
        return (vk_x1.X,vk_x1.Y);
    }
}




contract Verifier {
    using Pairing for *;
    struct VerifyingKey {
        Pairing.G1Point alpha;
        Pairing.G2Point beta;
        Pairing.G2Point gamma;
        Pairing.G2Point delta;
        Pairing.G1Point gamma_abc0;
    }
    struct Proof {
        Pairing.G1Point a;
        Pairing.G2Point b;
        Pairing.G1Point c;
    }
    function verifyingKey() view internal returns (VerifyingKey memory vk) {
      vk.alpha = Pairing.G1Point(uint256(0x07d2d5120da2a1211d3c29f6bf68a887068f473941fb7a1e422fc42120499648), uint256(0x2767870b00d8d95b00170ef9cec7641dc2e899ece4f1921eabe18f4c128a22b8));
vk.beta = Pairing.G2Point([uint256(0x13f5cc097decaa449a4289a5f48ed951d0ddc0b7ee907fd31051d1f22175ad14), uint256(0x0af1c6b0802a0f148f843475750257f5a7500b1f35362ca3f6c47b61892c13a1)], [uint256(0x2b61e1c95d9844cb8691d9a0e96f9300644bf301f0e5c2a4f5b19a075e8b40f4), uint256(0x11e1fe88f016af1ad24c3e79e83f36d5c6d83485d79d23665d48e352100dcf66)]);
vk.gamma = Pairing.G2Point([uint256(0x228450bd486a41f4366ea93e0cbfbeb9557599b766ff9b96af8c0a1183576a88), uint256(0x03408f619dd57d309a96172f7cab35150aa7f2ecabde7dfc0cda1599b75548e2)], [uint256(0x23139ad1c21b1cb302dd12540929c02100765a8091e8915d509dc7c80b2c48b0), uint256(0x2eb5eb67a238298e9c2aefe4c991960ea4a71cc27931f910846f3f86014a8092)]);
vk.delta = Pairing.G2Point([uint256(0x0fb1cbedb7b2964abe696b284d05782b1d7a7e6ebffee54398a02ccdea412352), uint256(0x2a3df894f11dd87f2ce1638242420995020dcf9c9c5539234f530ef34bdc67c2)], [uint256(0x250dcb7005df18c0eacc36cd0eebce4632ac697c1aa841ee3e46713d129ccac3), uint256(0x0723f2506a8a07dcf3283edfbe9fb849144b3c0eda15fc1b64c991ce9bb3624d)]);
vk.gamma_abc0 = Pairing.G1Point(uint256(0x14235118d96040a0872a5a57752888dd4fb911b246f77aa0a06f1d02da357edf), uint256(0x1532be8d96be0eb359df42527a16c67b3b826b8cc8629bb808c995aaca93c4d4));
    }
    
    function verify(uint32[] memory input1, Proof memory proof) internal view returns (uint) {
        //uint256 snark_scalar_field = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
        VerifyingKey memory vk = verifyingKey();
        
        Pairing.G1Point memory vk_x = Pairing.G1Point(0, 0);
        uint x;
        uint y;
        (x, y) = GetVK200.getvk(vk_x.X, vk_x.Y,input1);
        vk_x = Pairing.G1Point(uint256(x), uint256(y));
        vk_x = Pairing.addition(vk_x, vk.gamma_abc0);
        if(!Pairing.pairingProd4(
             proof.a, proof.b,
             Pairing.negate(vk_x), vk.gamma,
             Pairing.negate(proof.c), vk.delta,
             Pairing.negate(vk.alpha), vk.beta)) return 1;
        return 0;
    }
    function verifyTx(
            uint[2] memory a,
            uint[2][2] memory b,
            uint[2] memory c, uint32[60] memory input
        ) public returns (bool r) {
        Proof memory proof;
        proof.a = Pairing.G1Point(a[0], a[1]);
        proof.b = Pairing.G2Point([b[0][0], b[0][1]], [b[1][0], b[1][1]]);
        proof.c = Pairing.G1Point(c[0], c[1]);
        uint32[] memory inputValues1 = new uint32[](60);
      
        for(uint i = 0; i < 60; i++){
            inputValues1[i] = input[i];
        }
        
        if (verify(inputValues1,proof) == 0) {
            return true;
        } else {
            return false;
        }
    }
}

