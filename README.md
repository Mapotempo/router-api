Addok Wrapper
================
Offers an unified API for multiple routers based on countries distribution and other parameters like means of transport.
Build in Ruby with a [Grape](https://github.com/intridea/grape) REST [swagger](http://swagger.io/) API compatible with [geocodejson-spec](https://github.com/yohanboniface/geocodejson-spec).

Installation
============

Install package containing ogr2ogr exec from system package (GDAL).
In addok-wrapper as root directory:

```
bundle install
```


Configuration
=============

Adjust config/environments files.


Running
=======

```
bundle exec rake server
```

And in production mode:
```
APP_ENV=production bundle exec rake server
```

Usage
=====

The API is defined in Swagger format at
http://localhost:4899/swagger_doc
and can be tested with Swagger-UI
http://swagger.mapotempo.com/?url=http://router.mapotempo.com/swagger_doc

Capability
-----------------
Retrieve the available modes (eg routers) for apis by GET request.

```
http://localhost:4899/0.1/capability.json?&api_key=demo
```

Returns geocodejson (and geojson) valid result:
```
{
  "route": [
    {
      "mode": "mode1",
      "name": "translation1",
      "area": []
    },
    {
      "mode": "mode2",
      "name": "translation2",
      "area": []
    },
    {
      "mode": "mode3",
      "name": "translation3",
      "area": [
        "Area1", "Area2"
      ]
    }
  ],
  "matrix": [],
  "isoline": []
}
```

Route
---------------
Return the route between list of points using GET request.

For instance, route between Bordeaux, Mérignac and Talence
```
http://localhost:4899/0.1/route.json?api_key=demo&mode=osrm&geometry=true&loc=44.837778,-0.579197,44.844866,-0.656377,44.808047,-0.588598
```

Returns geocodejson (and geojson) valid result:
```
{
  "type": "FeatureCollection",
  "router": {
    "version": "draft",
    "licence": "ODbL",
    "attribution": "© OpenStreetMap contributors"
  },
  "features": [
    {
      "properties": {
        "router": {
          "total_distance": 16868,
          "total_time": 1374,
          "start_point": [
            -0.579197,
            44.837778
          ],
          "end_point": [
            -0.588598,
            44.808047
          ]
        }
      },
      "type": "Feature",
      "geometry": {
        "polylines": "kototAd|ib@hLiAnAyAnOaBvA|DnAjDtAhFrAlGvA~HnPr|@bEtVl@xDkDr@mJzB_VxFiCb@kz@zRcB~BeGzAoDz@b@xF`@vGnEnu@PdDaBhF\\nKvBpc@f@~LbCbi@^bJp@dQpBtj@\\pJb@lJdDnu@^xJ\\dIhBha@n@zHn@|F|@zFhBvI`B|HxCbNdB|HfI|_@xAbIdA|FuAvAaFpDkDpFoc@bVkCfCyArCsBlAuSxKwC|Aaa@dTwAt@qH|DgmAro@yAlAbC~s@VtHtA|`@p@dSz@~VtB`n@~Cj_ARrFv@jUV|H`EhlA^nKpBfl@NbFTnHRtGpCvv@d@hMZlIdCbv@P~EpBfl@J~E`Bxc@VlInCnz@h@hOnCny@hAt]~Bpq@`Clu@pC~v@`Clr@tFx`BzCvz@lCdo@hBpUxM~`AvMz}@x@zF~BbMx@tIHnMUzJo@v\\Mzg@s@xT]xPaB`~@]rYRpRbA`n@d@jUXhSt@nn@Rbb@qCz_AaBpd@eCp_AuBfu@aA`Zw@vJ{Dx\\yDtXwDlWkA`I}DtYsBdQgAlVa@zUn@hk@z@~bAPpj@F~mAWdW{AxgBOvaA_@hJsDnb@oFfd@eD`TcMlq@_Iha@qJ`WkBtEsDhJaBdHkNfyAwYpmB{Kv_AcPvrAuDj]oBhMmB`I[vEOnEYlLIhLKbPz@~ZzEje@tH~n@zD|W`Hno@gAfQQbCwDtAaDjAoEhClAhRQvDKtC{A|BuAzAo_@lb@oHtHkE`BwD]{BcAwFiCoLoDuL}A{l@}HwZmE}AOyH{HqLnWmFnLgHpTqIr[yCfSQ`FB~FgCj@mAzAaAfEBhDp@nCdBzB`Bh@pBMrCeC|NvMxEvNjBpMz@fGz@pSYdRy@fI{Ena@nRvVxKjGpF|CqF}CyKkGqOgS}AoBzEoa@x@gIXeR{@qS{@gGkBqMyEwN}NwM`AaFkA{HoAwAqCe@C_GPaFxCgSpIs[fHqTlFoLpLoWxHzH|ANvZlEzl@|HtL|AnLnDvFhCzBbAvD\\jEaBnHuHn_@mb@tA{AzA}BJuCPwDmAiRnEiC`DkAvDuAj@pCdBrAnBSnAkBLkEcA}B}@sBcCsJaHoo@{D}WuH_o@{Eke@{@_[JcPHiLXmLNoEZwElBaInBiMtDk]bPwrAzKw_AvYqmBjNgyA`BeHrDiJjBuEpJaW~Hia@bMmq@dDaTnFgd@rDob@^iJNwaAzAygBVeWG_nAQqj@{@_cAo@ik@`@{UfAmVrBeQ|DuYjAaIvDmWxDuXzDy\\v@wJ`AaZtBgu@dCq_A`Bqd@pC{_AScb@u@on@YiSe@kUcAan@SqR\\sY`Ba~@\\yPr@yTt@}JdA_GzEyIxAwBvBuCxAoBnDwGvAsEp@sFb@eHTgH_C_LyCgHiKiWuAwGCqHHgI\\}O~Aw]`@gUc@gd@i@kf@n@gU`Boc@TeHt@qRRgDhAcXjAaVz@aI|@mIfCmMhB}IdDgQ|AgGzC{IbOa_@fDyKvDmO|Vc{@lGsTrEkRlMqp@tByRhDig@hAiS~Den@LmSOqSyBeXeMm`Ag@eEsByo@Mal@IgZDoFpDYbUeAtXeAb]wB`Ls@pBGdXu@rQe@zCKfF[hn@kAbEWrF]xNs@dl@uCp`@cBfE_AjDeAhEwCdC{CdDqF~Sg_@`f@{z@pCcFnRk]tJ{PvR{\\dFaIjHwLdCiExD{GzTib@vQu[nQeYjB{CzKuQpBeDtEwHrC}FhCkF~GuNzJyQdKcQxOaXxFuJde@}w@rN{RtMmU~AmCrHyNdNwVnDqHvGcNpFkKvDcHv`@{s@lDyGfIuNjDgGpMgU|BkEbBeDjBsDpWwe@pTaa@bKeRzP}VdW{d@|KyRtBoDjAsBjA`CrB`EzAzC~AbDlX~i@fBnDxAnC|AqBjIiLnLgQb^fWvF`EdGnDtPbInCpAlCpAr]fPjJrEhDbBhDbBdJnE|JrEfD`BzEjCdH~EzC|BfB~A`CxAv_@tRjHpBlHvBfFdCrLbJ|LbK`ItHnBtBbErF|NtUnDhGpL`Srp@rhAxDrGzBtD~MbUfPhXxBrDj\\lj@zD|FvBjB`AvBjAfEfChBzCO`Ao@fBiEDcE_AsDoBkBbAsFzEybAxAeYtEslADkEBcERikA@}DzBGxoAiDdD]zEQ`j@r@@jD|Rxn@bAvAbRhPzArAxApAtObUbB`CtAtBgApFDbC^zBz@fBlAhAbDd@bBi@rAsAx@uBfCN|DrAra@dR",
        "type": "LineString"
      }
    }
  ]
}
```

Matrix
---------------
TBD

Isoline
---------------
TBD
