//
//  Shader.metal
//  MetalProject
//
//  Created by Chung Han Hsin on 2020/4/21.
//  Copyright © 2020 Chung Han Hsin. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

//所有的vertex shaders必須以關鍵字vertex開頭。函式必須至少返回頂點的最終位置
//packed_float3: (一個向量包含3個浮點數)的陣列的指標,如:每個頂點的位置。這個 [[ ... ]] 語法被用在宣告那些能被用作特定額外資訊的屬性,像是資源位置,shader輸入,內建變數。
//這裡你把這個引數用 [[ buffer(0) ]] 標記,來指明這個引數將會被在你程式碼中你傳送到你的vertex shader的第一塊buffer data所遍歷。
//vertex shader會接受一個名叫vertex_id的屬性的特定引數,它意味著它會被vertex數組裡特定的頂點所裝入。
//現在你基於vertex id來檢索vertex陣列中對應位置的vertex並把它返回。同時你把這個向量轉換為一個float4型別,最後的value設定為1.0(簡單的來說,這是3D數學要求的)。
vertex float4 basic_vertex(const device packed_float3* vertex_array[[buffer(0)]], unsigned int vid [[ vertex_id ]]) {
  return float4(vertex_array[vid], 1.0);
}


//所有fragment shaders必須以fragment關鍵字開始。這個函式必須至少返回fragment的最終顏色——你通過指定half4(一個顏色的RGBA值)來完成這個任務。注意,half4比float4在記憶體上更有效率,因為,你寫入了更少的GPU記憶體。
//這裡你返回(1,1,1,1)的顏色,也就是白色。
fragment half4 basic_fragment() {
   return half4(1.0);
}


//現在你已經建立了一個vertex shader和一個fragment shader
//你需要組合它們(加上一些配置資料)到一個特殊的物件
//它名叫render pipeline。
//Metal一個很酷的地方是,渲染器(shaders)是預編譯的
//render pipeline 配置會在你第一次設定它的時候被編譯,所以所有事情都極其高效。
