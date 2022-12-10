using System;
using System.Collections.Generic;
using System.IO;
using System.Net;
using System.Text;
using HomeWork22.Models;


namespace HomeWork22
{
    public class ApiHandler
    {
        /*
        /// <summary>
        /// Проверка корректности ИНН, представленного в виде строки
        /// За основу взят алгоритм http://www.rsdn.ru/Forum/Message.aspx?mid=647880
        /// </summary>
        /// <param name="value"></param>
        /// <returns></returns>
        public static bool IsINN(string value)
        {
            if (value.Length == 11)
            {
                if (value[0] != 'F')
                    return false;
                else
                    value = value.Remove(0, 1);
            }

            // должно быть 10 или 12 цифр
            if (!(value.Length == 10 || value.Length == 12))
                return false;
            else
            {
                try
                {
                    return IsINN(long.Parse(value));
                }
                catch
                {
                    return false;
                }
            }
        }*/

        /// <summary>
        /// Проверка корректности ИНН, представленного в виде числа
        /// За основу взят алгоритм http://www.rsdn.ru/Forum/Message.aspx?mid=647880
        /// </summary>
        /// <param name="value"></param>
        /// <returns></returns>
        public static bool IsINN(long value)
        {
            // должно быть 10 или 12 цифр
            if (value < 1000000000 || value >= 1000000000000)
                return false;

            int digits = (int)Math.Log10(value) + 1;
            if (!(digits == 10 || digits == 12))
                return false;

            // вычисляем контрольную сумму
            string s = value.ToString("D" + digits.ToString());
            int[] factors = digits == 10 ? arrMul10 : arrMul122;

        startCheck:

            long sum = 0;
            for (int i = 0; i < factors.Length; i++)
                sum += byte.Parse(s[i].ToString()) * factors[i];
            sum %= 11;
            sum %= 10;
            if (sum != byte.Parse(s[factors.Length].ToString()))
                return false;
            else if (digits == 12)
            {
                // используется маленький трюк:
                // запускается повторная проверка, начиная с метки startCheck,
                // но с другими коэффициентами, а чтобы исключить повторный вход 
                // в эту ветку, сбрасываем digits
                factors = arrMul121;
                digits = 0;
                goto startCheck;
            }
            else
                return true;
        }

        #region Коффициенты для проверки ИНН (метод IsINN)

        static readonly int[] arrMul10 = { 2, 4, 10, 3, 5, 9, 4, 6, 8 };
        static readonly int[] arrMul121 = { 7, 2, 4, 10, 3, 5, 9, 4, 6, 8 };
        static readonly int[] arrMul122 = { 3, 7, 2, 4, 10, 3, 5, 9, 4, 6, 8 };

        #endregion Коффициенты для проверки ИНН (метод IsINN)

        /*
        /// <summary>
        /// Получение последних постов через внешнее API
        /// </summary>
        /// <param name="limit">Количество полученных записей</param>
        public static List<Post> GetLatestPosts(int limit)
        {
            string url = "https://jsonplaceholder.typicode.com/posts";
            HttpWebRequest req =
                (HttpWebRequest)WebRequest.Create(url);
            HttpWebResponse resp = (HttpWebResponse)req.GetResponse();

            string resultJson;
            using (StreamReader reader = new StreamReader(
                 resp.GetResponseStream(), Encoding.UTF8))
            {
                resultJson = reader.ReadToEnd();
                List<Post> list = 
                    JsonConvert.DeserializeObject<List<Post>>(resultJson);

                return list.Take(limit).ToList();
            }            
        }*/

        /*
         public static Byte[] GetLatestPosts(int limit)
         {
             string url = "https://jsonplaceholder.typicode.com/posts";
             HttpWebRequest req =
                 (HttpWebRequest)WebRequest.Create(url);
             HttpWebResponse resp = (HttpWebResponse)req.GetResponse();

             string resultJson;
             using (StreamReader reader = new StreamReader(
                  resp.GetResponseStream(), Encoding.UTF8))
             {
                 resultJson = reader.ReadToEnd();
                 List<Post> list =
                     JsonConvert.DeserializeObject<List<Post>>(resultJson);
                 return Encoding.UTF8.GetBytes(resultJson);
             }
         }*/

        /*
        public static string GetString()
        {
            return "1234567";
        }*/

    }
}
