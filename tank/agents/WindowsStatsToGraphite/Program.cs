using System;
using System.Diagnostics;
using System.Threading;
using Graphite;

namespace PerfCounters
{
    class Program
    {
        static void Main(string[] args)
        {
            var metricPrefix = "one_sec.monitor";
            if (args.Length > 0)
            {
                metricPrefix = args[0];
            }
            AppDomain.CurrentDomain.ProcessExit += CurrentDomain_ProcessExit;         
            StaticMetricsPipeProvider.Instance.Start();
            var cpuCounter = new PerformanceCounter("Processor", "% Processor Time", "_Total");
            var memCounter = new PerformanceCounter("Memory", "Available MBytes");
            var cpu = 0;
            var memory = 0;

            while (true)
            {
                Thread.Sleep(1000);
                cpu = (int)cpuCounter.NextValue();
                memory = (int) memCounter.NextValue();
                try
                {
                    StaticMetricsPipeProvider.Instance.Current.Raw(string.Format("{0}.cpu", metricPrefix), cpu);
                    StaticMetricsPipeProvider.Instance.Current.Raw(string.Format("{0}.free_memory", metricPrefix), memory);
                }
                catch (Exception)
                {
                }
            }

        }

        static void CurrentDomain_ProcessExit(object sender, EventArgs e)
        {
            Console.WriteLine("exit");
            StaticMetricsPipeProvider.Instance.Stop();
        }

        private static void CollectnPopulatePerfCounters()
        {
            try
            {
                foreach (var pc in System.Diagnostics.PerformanceCounterCategory.GetCategories())
                {
                        try
                        {
                            foreach (var insta in pc.GetInstanceNames())
                            {
                                try
                                {
                                    foreach (PerformanceCounter cntr in pc.GetCounters(insta))
                                    {
                                        using (System.IO.StreamWriter sw = new System.IO.StreamWriter("C:\\amit.txt", true))
                                        {
                                            sw.WriteLine("--------------------------------------------------------------------");
                                            sw.WriteLine("Category Name : " + pc.CategoryName);
                                            sw.WriteLine("Counter Name : " + cntr.CounterName);
                                            sw.WriteLine("Explain Text : " + cntr.CounterHelp);
                                            sw.WriteLine("Instance Name: " + cntr.InstanceName);
                                            sw.WriteLine("Value : " + Convert.ToString(Math.Round(cntr.NextValue(), 2)) + "%");
                                            sw.WriteLine("Counter Type : " + cntr.CounterType);
                                            sw.WriteLine("--------------------------------------------------------------------");
                                        }
                                    }
                                }
                                catch (Exception) { }
                            }
                        }
                        catch (Exception) { }
                }
            }
            catch (Exception) { }
        }
    }
}
